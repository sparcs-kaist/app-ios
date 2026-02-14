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

  var isLoadingMore: Bool { get }
  var hasMorePages: Bool { get }

  func fetchInitialPosts() async
  func loadNextPage() async
  func refreshItem(postID: Int)
  func removePost(postID: Int)
  func bind()
}
