//
//  FeedViewModel.swift
//  soap
//
//  Created by Soongyu Kwon on 18/08/2025.
//

import Foundation
import Observation
import Factory
import BuddyDomain

@MainActor
@Observable
public final class FeedViewModel: FeedViewModelProtocol {
  // MARK: - Properteis
  public var state: FeedViewState = .loading
  public var posts: [FeedPost] = []
  public var alertState: AlertState? = nil
  public var isAlertPresented: Bool = false

  private var nextCursor: String? = nil
  private var hasNext: Bool = false

  public init() {}

  // MARK: - Dependencies
  @ObservationIgnored @Injected(\.authUseCase) private var authUseCase: AuthUseCaseProtocol?
  @ObservationIgnored @Injected(\.feedPostUseCase) private var feedPostUseCase: FeedPostUseCaseProtocol?

  // MARK: - Functions
  public func signOut() async throws {
    guard let authUseCase else { return }
    try await authUseCase.signOut()
  }

  public func fetchInitialData() async {
    guard let feedPostUseCase else { return }

    do {
      let page: FeedPostPage = try await feedPostUseCase.fetchPosts(cursor: nil, page: 20)
      self.posts = page.items
      self.nextCursor = page.nextCursor
      self.hasNext = page.hasNext
      self.state = .loaded
    } catch {
      self.state = .error(message: error.localizedDescription)
    }
  }

  public func deletePost(postID: String) async {
    guard let feedPostUseCase else { return }

    do {
      try await feedPostUseCase.deletePost(postID: postID)
      self.posts.removeAll { $0.id == postID }
    } catch {
      self.alertState = .init(title: String(localized: "Unable to delete post."), message: error.localizedDescription)
      self.isAlertPresented = true
    }
  }
}
