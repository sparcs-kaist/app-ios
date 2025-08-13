//
//  MockPostListViewModel.swift
//  soap
//
//  Created by Soongyu Kwon on 15/02/2025.
//

import SwiftUI
import Observation

@Observable
class MockPostListViewModel: PostListViewModelProtocol {
  // MARK: - ViewModel Properties
  var state: PostListViewModel.ViewState = .loaded(posts: AraPost.mockList)
  var board: AraBoard = AraBoard.mock
  var posts: [AraPost] = AraPost.mockList
  var searchKeyword: String = ""
  var isLoadingMore: Bool = false
  var hasMorePages: Bool = true

  // MARK: - Functions
  func fetchInitialPosts() async {
    // Mock implementation
  }
  
  func loadNextPage() async {
    // Mock implementation
  }

  func refreshItem(postID: Int) {
    
  }

  func bind() { }
}
