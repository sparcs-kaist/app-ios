//
//  AraMyPostViewModel.swift
//  soap
//
//  Created by 하정우 on 8/31/25.
//

import Foundation
import Combine
import Factory
import BuddyDomain

@MainActor
protocol AraMyPostViewModelProtocol: Observable {
  var posts: [AraPost] { get }
  var state: AraMyPostViewModel.ViewState { get }
  var type: AraMyPostViewModel.PostType { get set }
  var user: AraUser? { get }
  
  var searchKeyword: String { get set }
  
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
    didSet {
      searchKeywordSubject.send(searchKeyword)
    }
  }
  var cancellables = Set<AnyCancellable>()
  var searchKeywordSubject = PassthroughSubject<String, Never>()

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
    cancellables.removeAll()
    
    let searchPublisher = searchKeywordSubject
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .removeDuplicates()
    
    searchPublisher
      .sink { [weak self] _ in
        guard let self else { return }
        self.state = .loading
      }
      .store(in: &cancellables)
    
    searchPublisher
      .debounce(for: .milliseconds(350), scheduler: DispatchQueue.main)
      .sink { [weak self] _ in
        guard let self else { return }
        Task {
          await self.fetchInitialPosts()
        }
      }
      .store(in: &cancellables)
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
//      logger.error(error)
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
//      logger.error(error)
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
