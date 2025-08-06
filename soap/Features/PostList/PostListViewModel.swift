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
  var posts: [AraPost] { get }

  func fetchInitialPosts() async
}

@Observable
class PostListViewModel: PostListViewModelProtocol {
  var postList: [Post] = Post.mockList

  // MARK: - Properties
  enum ViewState {
    case loading
    case loaded(posts: [AraPost])
    case error(message: String)
  }
  var state: ViewState = .loading
  var board: AraBoard
  var posts: [AraPost] = []

  var pages: Int? = nil
  var items: Int? = nil
  var currentPage: Int? = nil

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
      let page = try await araBoardRepository.fetchPosts(boardID: board.id, page: 1)
      self.pages = page.pages
      self.items = page.items
      self.currentPage = page.currentPage
      self.posts = page.results
      self.state = .loaded(posts: self.posts)
    } catch {
      logger.error(error)
      state = .error(message: error.localizedDescription)
    }
  }
}
