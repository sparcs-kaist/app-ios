//
//  PreviewAraMyPostViewModel.swift
//  BuddyPreviewSupport
//
//  Created by 하정우 on 5/13/2026.
//

import Observation
import BuddyDomain

@Observable
@MainActor
public final class PreviewAraMyPostViewModel: AraMyPostViewModelProtocol {
  public var posts: [AraPost]
  public var state: AraMyPostViewState
  public var type: AraMyPostType
  public var searchKeyword: String = ""
  public var isLoadingMore: Bool = false

  private let user: AraUser

  public init(
    type: AraMyPostType,
    state: AraMyPostViewState? = nil,
    posts: [AraPost] = AraPost.mockList
  ) {
    self.type = type
    self.posts = posts
    self.state = state ?? .loaded(posts: posts)
    self.user = AraUser(
      id: 984,
      nickname: "오열하는 운영체제 및 실험",
      nicknameUpdatedAt: nil,
      allowNSFW: false,
      allowPolitical: true
    )
  }

  public func bind() {}
  public func fetchUserIfNeeded() async {
    _ = user
  }
  public func fetchInitialPosts() async {}
  public func loadNextPage() async {}
  public func refreshItem(postID: Int) {}
}
