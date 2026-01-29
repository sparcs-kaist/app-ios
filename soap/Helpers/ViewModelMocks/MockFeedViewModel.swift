//
//  MockFeedViewModel.swift
//  soap
//
//  Created by 하정우 on 11/4/25.
//

import Foundation
import BuddyDomain
import BuddyFeatureFeed

class MockFeedViewModel: FeedViewModelProtocol {
  // MARK: - Properties
  var state: FeedViewModel.ViewState = .loaded
  var posts: [FeedPost] = FeedPost.mockList

  // MARK: - Functions
  func signOut() async throws {
    // Mock implementation
  }
  
  func fetchInitialData() async {
    // Mock implementation
  }
  
  func deletePost(postID: String) async throws {
    // Mock implementation
  }
}
