//
//  AraMyPostViewModel.swift
//  soap
//
//  Created by 하정우 on 8/31/25.
//

import Foundation
import Observation
import Factory
import BuddyDomain
import os

private let logger = Logger(subsystem: "org.sparcs.soap", category: "AraMyPostViewModel")

@MainActor
protocol AraMyPostViewModelProtocol: Observable {
  var posts: [AraPost] { get }
  var state: AraMyPostViewModel.ViewState { get }
  var type: AraMyPostViewModel.PostType { get set }
  var user: AraUser? { get }
  
  var searchKeyword: String { get set }
  var isLoadingMore: Bool { get }
  
  func bind()
  func fetchInitialPosts() async
  func loadNextPage() async
  func refreshItem(postID: Int)
}

@Observable
class AraMyPostViewModel: AraMyPostViewModelProtocol {
  enum ViewState: Equatable {
    case loading
    case loaded(posts: [AraPost])
    case error(message: String)
  }
  
  enum PostType: String, CaseIterable {
    case all = "All"
    case bookmark = "Bookmarked"
  }
  
  @ObservationIgnored @Injected(\.araBoardUseCase) private var araBoardUseCase: AraBoardUseCaseProtocol?

  var posts: [AraPost] = []
  var state: ViewState = .loading
  var type: PostType = .all
  var user: AraUser?
  
  // Search Properties
  var searchKeyword: String = "" {
    didSet { scheduleSearch() }
  }
  @ObservationIgnored private var searchTask: Task<Void, Never>?
  @ObservationIgnored private var lastSearchKeyword: String?

  // Infinite Scroll Properties
  var isLoadingMore: Bool = false
  var hasMorePages: Bool = true
  var currentPage: Int = 1
  var totalPages: Int = 0
  var pageSize: Int = 30
  
  init(user: AraUser?, type: PostType) {
    self.user = user
    self.type = type
  }
  
  func bind() {
    searchTask?.cancel()
    lastSearchKeyword = nil
  }

  private func scheduleSearch() {
    let keyword = searchKeyword.trimmingCharacters(in: .whitespacesAndNewlines)
    guard keyword != lastSearchKeyword else { return }
    lastSearchKeyword = keyword
    state = .loading

    searchTask?.cancel()
    searchTask = Task { [weak self] in
      try? await Task.sleep(for: .milliseconds(350))
      guard !Task.isCancelled, let self else { return }
      await self.fetchInitialPosts()
    }
  }
  
  func fetchInitialPosts() async {
    guard let user = user else { return }
    guard let araBoardUseCase else { return }

    do {
      var page: AraPostPage
      switch self.type {
      case .all:
        page = try await araBoardUseCase.fetchPosts(
          type: .user(userID: user.id),
          page: 1,
          pageSize: pageSize,
          searchKeyword: searchKeyword.isEmpty ? nil : searchKeyword
        )
      case .bookmark:
        page = try await araBoardUseCase.fetchBookmarks(
          page: 1,
          pageSize: pageSize)
      }
      self.totalPages = page.pages
      self.currentPage = page.currentPage
      self.posts = page.results
      self.hasMorePages = currentPage < totalPages
      self.state = .loaded(posts: self.posts)
    } catch {
      logger.error("Failed to fetch posts: \(error.localizedDescription, privacy: .public)")
      state = .error(message: error.localizedDescription)
    }
  }
  
  func loadNextPage() async {
    guard let user = user else { return }
    guard !isLoadingMore && hasMorePages else { return }
    guard let araBoardUseCase else { return }

    isLoadingMore = true
    
    do {
      let nextPage = currentPage + 1
      var page: AraPostPage
      switch self.type {
      case .all:
        page = try await araBoardUseCase.fetchPosts(
          type: .user(userID: user.id),
          page: nextPage,
          pageSize: pageSize,
          searchKeyword: searchKeyword.isEmpty ? nil : searchKeyword
        )
      case .bookmark:
        page = try await araBoardUseCase.fetchBookmarks(
          page: nextPage,
          pageSize: pageSize
        )
      }
      self.totalPages = page.pages
      self.currentPage = page.currentPage
      self.posts.append(contentsOf: page.results)
      self.hasMorePages = currentPage < totalPages
      self.state = .loaded(posts: self.posts)
      self.isLoadingMore = false
    } catch {
      logger.error("Failed to load next page: \(error.localizedDescription, privacy: .public)")
      state = .error(message: error.localizedDescription)
    }
  }
  
  func refreshItem(postID: Int) {
    guard let araBoardUseCase else { return }
    
    Task {
      guard let updated: AraPost = try? await araBoardUseCase.fetchPost(origin: .none, postID: postID) else { return }

      if let idx = self.posts.firstIndex(where: { $0.id == updated.id }) {
        var previousPost: AraPost = self.posts[idx]
        previousPost.upvotes = updated.upvotes
        previousPost.downvotes = updated.downvotes
        previousPost.commentCount = updated.commentCount
        self.posts[idx] = previousPost
        self.state = .loaded(posts: self.posts)
      }
    }
  }
}
