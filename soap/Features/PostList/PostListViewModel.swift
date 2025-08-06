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
  var postList: [Post] { get }

  var state: PostListViewModel.ViewState { get }
  var board: AraBoard { get }
  var posts: [AraPostHeader] { get }
  var isLoadingMore: Bool { get }
  var hasMorePages: Bool { get }

  func fetchInitialPosts() async
  func loadNextPage() async
}

@Observable
class PostListViewModel: PostListViewModelProtocol {
  var postList: [Post] = Post.mockList

  // MARK: - Properties
  enum ViewState: Equatable {
    case loading
    case loaded(posts: [AraPostHeader])
    case error(message: String)
  }
  var state: ViewState = .loading
  var board: AraBoard
  var posts: [AraPostHeader] = []
  
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
}
