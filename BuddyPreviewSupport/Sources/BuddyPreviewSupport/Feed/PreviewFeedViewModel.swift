//
//  PreviewFeedViewModel.swift
//  BuddyFeature
//

import Foundation
import Observation
import BuddyDomain

@MainActor
@Observable
public final class PreviewFeedViewModel: FeedViewModelProtocol {
  public var state: FeedViewState
  public var posts: [FeedPost]
  public var alertState: AlertState?
  public var isAlertPresented: Bool = false

  public init(state: FeedViewState = .loaded, posts: [FeedPost] = []) {
    self.state = state
    self.posts = posts
  }

  public func signOut() async throws {}
  public func fetchInitialData() async {}
  public func deletePost(postID: String) async {}

  public func openSettingsTapped() {}
  public func refreshFeed() async {}
  public func writeFeedButtonTapped() {}
}
