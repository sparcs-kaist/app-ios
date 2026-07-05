//
//  UserPostListViewModel.swift
//  soap
//
//  Created by Soongyu Kwon on 16/08/2025.
//

import SwiftUI
import Observation
import Factory
import BuddyDomain

@Observable
class UserPostListViewModel: UserPostListViewModelProtocol {
  // MARK: - Properties
  var state: UserPostListViewState = .loading
  var user: AraPostAuthor
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

  // MARK: - Dependencies
  @ObservationIgnored @Injected(
    \.araBoardUseCase
  ) private var araBoardUseCase: AraBoardUseCaseProtocol?
  @ObservationIgnored @Injected(
    \.analyticsService
  ) private var analyticsService: AnalyticsServiceProtocol?

  // MARK: - Initialiser
  init(user: AraPostAuthor) {
    self.user = user
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
    guard let userID = Int(user.id) else { return }
    guard let araBoardUseCase else { return }

    do {
      let page = try await araBoardUseCase.fetchPosts(
        type: .user(userID: userID),
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
      state = .error(message: error.localizedDescription)
    }
  }

  func loadNextPage() async {
    guard let userID = Int(user.id) else { return }
    guard !isLoadingMore && hasMorePages else { return }
    guard let araBoardUseCase else { return }

    isLoadingMore = true

    do {
      let nextPage = currentPage + 1
      let page = try await araBoardUseCase.fetchPosts(
        type: .user(userID: userID),
        page: nextPage,
        pageSize: pageSize,
        searchKeyword: searchKeyword.isEmpty ? nil : searchKeyword
      )

      self.currentPage = page.currentPage
      self.posts.append(contentsOf: page.results)
      self.hasMorePages = currentPage < totalPages
      self.state = .loaded(posts: self.posts)
      self.isLoadingMore = false
      analyticsService?.logEvent(PostListViewEvent.nextPageLoaded)
    } catch {
      self.isLoadingMore = false
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
