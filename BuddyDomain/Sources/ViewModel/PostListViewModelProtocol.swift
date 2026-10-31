//
//  PostListViewModelProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 14/02/2026.
//

import Foundation

@MainActor
public protocol PostListViewModelProtocol: Observable {
  var state: PostListViewState { get }
  var board: AraBoard { get }
  var posts: [AraPost] { get }
  var searchKeyword: String { get set }
  /// Shows only posts under this topic; `nil` for the whole board.
  var selectedTopic: AraBoardTopic? { get set }

  var isLoadingMore: Bool { get }
  var hasMorePages: Bool { get }

  func fetchInitialPosts() async
  func loadNextPage()
  func refreshItem(postID: Int)
  /// Greys the post out in the list as soon as it is opened, ahead of the next fetch.
  func markRead(postID: Int)
  func removePost(postID: Int)
  func bind()
}
