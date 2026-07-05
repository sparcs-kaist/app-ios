//
//  PostListViewModel.swift
//  soap
//
//  Created by Soongyu Kwon on 15/02/2025.
//

import SwiftUI
import Observation
import Factory
import BuddyDomain
import os

private let logger = Logger(subsystem: "org.sparcs.soap", category: "PostListViewModel")

@Observable
class PostListViewModel: PostListViewModelProtocol {
  // MARK: - Properties
  var state: PostListViewState = .loading
  var board: AraBoard
  var posts: [AraPost] = []

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

  //MARK: - Dependencies
  @ObservationIgnored @Injected(
    \.araBoardUseCase
  ) private var araBoardUseCase: AraBoardUseCaseProtocol?
  @ObservationIgnored @Injected(
    \.analyticsService
  ) private var analyticsService: AnalyticsServiceProtocol?

  // MARK: - Initialiser
  init(board: AraBoard) {
    self.board = board
  }

  func bind() {
    searchTask?.cancel()
    lastSearchKeyword = nil
  }

  private func scheduleSearch() {
    let keyword = searchKeyword.trimmingCharacters(in: .whitespacesAndNewlines)
    guard keyword != lastSearchKeyword else { return }
    lastSearchKeyword = keyword

    searchTask?.cancel()
    searchTask = Task { [weak self] in
      try? await Task.sleep(for: .milliseconds(350))
      guard !Task.isCancelled, let self else { return }
      if !keyword.isEmpty {
        self.analyticsService?.logEvent(PostListViewEvent.searchPerformed(keyword: keyword))
      }
      await self.fetchInitialPosts()
    }
  }

  func fetchInitialPosts() async {
    guard let araBoardUseCase else { return }

    do {
      let page = try await araBoardUseCase.fetchPosts(
        type: .board(boardID: board.id),
        page: 1,
        pageSize: pageSize,
        searchKeyword: searchKeyword.isEmpty ? nil : searchKeyword
      )
      self.totalPages = page.pages
      self.currentPage = page.currentPage
      self.posts = page.results
      self.hasMorePages = currentPage < totalPages
      self.state = .loaded(posts: self.posts)
      analyticsService?.logEvent(PostListViewEvent.postsRefreshed)
    } catch {
      logger.error("Failed to load posts: \(error.localizedDescription, privacy: .public)")
      state = .error(message: error.localizedDescription)
    }
  }

  func loadNextPage() {
    guard !isLoadingMore && hasMorePages else { return }
    guard let araBoardUseCase else { return }

    isLoadingMore = true

    let nextPage = currentPage + 1
    let boardID = board.id
    let ps = pageSize
    let sk = searchKeyword.isEmpty ? nil : searchKeyword

    Task.detached {
      do {
        let page = try await araBoardUseCase.fetchPosts(
          type: .board(boardID: boardID),
          page: nextPage,
          pageSize: ps,
          searchKeyword: sk
        )

        await MainActor.run { [page] in
          self.currentPage = page.currentPage
          self.posts.append(contentsOf: page.results)
          self.hasMorePages = self.currentPage < self.totalPages
          self.state = .loaded(posts: self.posts)
          self.analyticsService?.logEvent(PostListViewEvent.nextPageLoaded)
          self.isLoadingMore = false
        }
      } catch {
        logger.error("Failed to load posts: \(error.localizedDescription, privacy: .public)")
        await MainActor.run {
          self.isLoadingMore = false
        }
      }
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

  func removePost(postID: Int) {
    if let idx = self.posts.firstIndex(where: { $0.id == postID }) {
      self.posts.remove(at: idx)
      self.state = .loaded(posts: self.posts)
    }
  }
}
