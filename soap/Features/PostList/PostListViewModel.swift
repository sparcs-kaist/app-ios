//
//  PostListViewModel.swift
//  soap
//
//  Created by Soongyu Kwon on 15/02/2025.
//

import SwiftUI
import Observation

protocol PostListViewModelProtocol: Observable {
  var postList: [Post] { get }

  var state: PostListViewModel.ViewState { get }
  var board: AraBoard { get }
}

@Observable
class PostListViewModel: PostListViewModelProtocol {
  var postList: [Post] = Post.mockList

  enum ViewState {
    case loading
    case loaded
    case error(message: String)
  }
  var state: ViewState = .loading

  var board: AraBoard

  // MARK: - Initialiser
  init(board: AraBoard) {
    self.board = board
  }
  
}
