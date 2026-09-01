//
//  PreviewUserPostListViewModel.swift
//  BuddyPreviewSupport
//
//  Created by Soongyu Kwon on 14/02/2026.
//

import Foundation
import BuddyDomain

@MainActor
@Observable
public final class PreviewUserPostListViewModel: UserPostListViewModelProtocol {
  public var state: UserPostListViewState
  public var user: AraPostAuthor
  public var posts: [AraPost]
  public var searchKeyword: String
  public var isLoadingMore: Bool
  public var hasMorePages: Bool

  public init(
    state: UserPostListViewState,
    user: AraPostAuthor,
    posts: [AraPost] = [],
    searchKeyword: String = "",
    isLoadingMore: Bool = false,
    hasMorePages: Bool = false
  ) {
    self.state = state
    self.user = user
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


