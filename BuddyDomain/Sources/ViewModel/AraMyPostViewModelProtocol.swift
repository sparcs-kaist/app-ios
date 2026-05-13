//
//  AraMyPostViewModelProtocol.swift
//  BuddyDomain
//
//  Created by 하정우 on 5/13/2026.
//

import Observation

@MainActor
public protocol AraMyPostViewModelProtocol: Observable {
  var posts: [AraPost] { get }
  var state: AraMyPostViewState { get }
  var type: AraMyPostType { get set }
  var searchKeyword: String { get set }
  var isLoadingMore: Bool { get }

  func bind()
  func fetchUserIfNeeded() async
  func fetchInitialPosts() async
  func loadNextPage() async
  func refreshItem(postID: Int)
}

public enum AraMyPostType: String, CaseIterable {
  case all = "All"
  case bookmark = "Bookmarked"
}
