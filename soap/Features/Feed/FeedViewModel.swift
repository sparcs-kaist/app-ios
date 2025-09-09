//
//  FeedViewModel.swift
//  soap
//
//  Created by Soongyu Kwon on 18/08/2025.
//

import Foundation
import Observation
import Factory

@MainActor
protocol FeedViewModelProtocol: Observable {
  var state: FeedViewModel.ViewState { get }
  var posts: [FeedPost] { get set }

  func signOut() async throws
  func fetchInitialData() async
  func deletePost(postID: String) async throws
}

@MainActor
@Observable
final class FeedViewModel: FeedViewModelProtocol {
  enum ViewState: Equatable {
    case loading
    case loaded
    case error(message: String)
  }

  // MARK: - Properteis
  var state: ViewState = .loading
  var posts: [FeedPost] = []
  private var nextCursor: String? = nil
  private var hasNext: Bool = false

  // MARK: - Dependencies
  @ObservationIgnored @Injected(\.authUseCase) private var authUseCase: AuthUseCaseProtocol
  @ObservationIgnored @Injected(
    \.feedPostRepository
  ) private var feedPostRepository: FeedPostRepositoryProtocol

  // MARK: - Functions
  func signOut() async throws {
    try await authUseCase.signOut()
  }

  func fetchInitialData() async {
    do {
      let page: FeedPostPage = try await feedPostRepository.fetchPosts(cursor: nil, page: 20)
      self.posts = page.items
      self.nextCursor = page.nextCursor
      self.hasNext = page.hasNext
      self.state = .loaded
    } catch {
      logger.error(error)
      self.state = .error(message: error.localizedDescription)
    }
  }

  func deletePost(postID: String) async throws {
    try await feedPostRepository.deletePost(postID: postID)
    self.posts.removeAll { $0.id == postID }
  }
}
