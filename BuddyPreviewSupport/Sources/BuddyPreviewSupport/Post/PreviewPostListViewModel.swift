//
//  PreviewPostListViewModel.swift
//  BuddyPreviewSupport
//
//  Created by Soongyu Kwon on 14/02/2026.
//

import Foundation
import BuddyDomain

@MainActor
@Observable
public final class PreviewPostListViewModel: PostListViewModelProtocol {
  public var state: PostListViewState
  public var board: AraBoard
  public var posts: [AraPost]
  public var searchKeyword: String
  public var isLoadingMore: Bool
  public var hasMorePages: Bool

  public init(
    state: PostListViewState,
    board: AraBoard,
    posts: [AraPost] = [],
    searchKeyword: String = "",
    isLoadingMore: Bool = false,
    hasMorePages: Bool = false
  ) {
    self.state = state
    self.board = board
    self.posts = posts
    self.searchKeyword = searchKeyword
    self.isLoadingMore = isLoadingMore
    self.hasMorePages = hasMorePages
  }

  public func fetchInitialPosts() async { }

  public func loadNextPage() async { }

  public func refreshItem(postID: Int) { }

  public func removePost(postID: Int) { }

  public func bind() { }
}

