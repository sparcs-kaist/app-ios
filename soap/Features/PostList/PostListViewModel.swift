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
    \.araBoardRepository
  ) private var araBoardRepository: AraBoardRepositoryProtocol

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
    do {
      let page = try await araBoardRepository.fetchPosts(
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
    } catch {
      logger.error(error)
      state = .error(message: error.localizedDescription)
    }
  }
  
  func loadNextPage() async {
    guard !isLoadingMore && hasMorePages else { return }
    
    isLoadingMore = true
    
    do {
      let nextPage = currentPage + 1
      let page = try await araBoardRepository.fetchPosts(
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
    } catch {
      logger.error(error)
      self.isLoadingMore = false
    }
  }

  func refreshItem(postID: Int) {
    Task {
      guard let updated: AraPost = try? await araBoardRepository.fetchPost(origin: .none, postID: postID) else { return }

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
