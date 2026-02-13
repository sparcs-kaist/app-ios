//
//  PostListViewModel.swift
//  soap
//
//  Created by Soongyu Kwon on 15/02/2025.
//

import SwiftUI
import Combine
import Observation
import Factory
import BuddyDomain

@MainActor
protocol PostListViewModelProtocol: Observable {
  var state: PostListViewModel.ViewState { get }
  var board: AraBoard { get }
  var posts: [AraPost] { get }
  var searchKeyword: String { get set }

  var isLoadingMore: Bool { get }
  var hasMorePages: Bool { get }

  func fetchInitialPosts() async
  func loadNextPage() async
  func refreshItem(postID: Int)
  func removePost(postID: Int)
  func bind()
}

@Observable
class PostListViewModel: PostListViewModelProtocol {
  // MARK: - Properties
  enum ViewState: Equatable {
    case loading
    case loaded(posts: [AraPost])
    case error(message: String)
  }
  var state: ViewState = .loading
  var board: AraBoard
  var posts: [AraPost] = []

  // Search Properties
  var searchKeyword: String = "" {
    didSet { searchKeywordSubject.send(searchKeyword) }
  }
  @ObservationIgnored private var cancellables = Set<AnyCancellable>()
  @ObservationIgnored private let searchKeywordSubject = PassthroughSubject<String, Never>()

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
    cancellables.removeAll()

    let searchPublisher = searchKeywordSubject
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .removeDuplicates()

    searchPublisher
      .debounce(for: .milliseconds(350), scheduler: DispatchQueue.main)
      .sink { [weak self] keyword in
        guard let self else { return }
        Task {
          if !keyword.isEmpty {
            self.analyticsService?.logEvent(PostListViewEvent.searchPerformed(keyword: keyword))
          }
          await self.fetchInitialPosts()
        }
      }
      .store(in: &cancellables)
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
      state = .error(message: error.localizedDescription)
    }
  }

  func loadNextPage() async {
    guard !isLoadingMore && hasMorePages else { return }
    guard let araBoardUseCase else { return }

    isLoadingMore = true

    do {
      let nextPage = currentPage + 1
      let page = try await araBoardUseCase.fetchPosts(
        type: .board(boardID: board.id),
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
