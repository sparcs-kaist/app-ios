//
//  PostListViewModel.swift
//  soap
//
//  Created by Soongyu Kwon on 15/02/2025.
//

import SwiftUI
import Observation
import Factory

@MainActor
protocol PostListViewModelProtocol: Observable {
  var state: PostListViewModel.ViewState { get }
  var board: AraBoard { get }
  var posts: [AraPost] { get }
  var isLoadingMore: Bool { get }
  var hasMorePages: Bool { get }

  func fetchInitialPosts() async
  func loadNextPage() async
  func refreshItem(postID: Int)
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
  
  // 무한 스크롤 관련 속성들
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

  func fetchInitialPosts() async {
    do {
      let page = try await araBoardRepository.fetchPosts(boardID: board.id, page: 1, pageSize: pageSize)
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
      let page = try await araBoardRepository.fetchPosts(boardID: board.id, page: nextPage, pageSize: pageSize)
      
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
}
