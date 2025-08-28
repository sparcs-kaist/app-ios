//
//  MockAraSettingsViewModel.swift
//  soap
//
//  Created by 하정우 on 8/28/25.
//

import Foundation

@Observable
class MockAraSettingsViewModel: AraSettingsViewModelProtocol {
  // MARK: - Properties
  var araUser: AraMe?
  var araNickname: String = "유능한 시조새_0b4c"
  var araNicknameUpdatable: Bool = false
  var araNicknameUpdatableSince: Date? = Calendar.current.date(byAdding: .day, value: 1, to: Date())
  var araAllowNSFWPosts: Bool = false
  var araAllowPoliticalPosts: Bool = false
  var state: AraSettingsViewModel.ViewState = .loading
  var posts: [AraPost] = AraPost.mockList
  
  // MARK: - Functions
  func fetchAraUser() async {
    // Mock implementation
  }
  
  func updateAraNickname() async throws {
    // Mock implementation
  }
  
  func updateAraPostVisibility() async {
    // Mock implementation
  }
  
  func fetchInitialPosts() async {
    // Mock implementation
  }
  
  func loadNextPage() async {
    // Mock implementation
  }
  
  func refreshItem(postID: Int) {
    // Mock implementation
  }
}
