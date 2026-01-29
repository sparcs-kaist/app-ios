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
public protocol FeedViewModelProtocol: Observable {
  var state: FeedViewModel.ViewState { get }
  var posts: [FeedPost] { get set }

  func signOut() async throws
  func fetchInitialData() async
  func deletePost(postID: String) async throws
}

@MainActor
@Observable
public final class FeedViewModel: FeedViewModelProtocol {
  public enum ViewState: Equatable {
    case loading
    case loaded
    case error(message: String)
  }

  // MARK: - Properteis
  public var state: ViewState = .loading
  public var posts: [FeedPost] = []
  private var nextCursor: String? = nil
  private var hasNext: Bool = false

  public init() {}

  // MARK: - Dependencies
  @ObservationIgnored @Injected(\.authUseCase) private var authUseCase: AuthUseCaseProtocol?
  @ObservationIgnored @Injected(
    \.feedPostRepository
  ) private var feedPostRepository: FeedPostRepositoryProtocol?

  // MARK: - Functions
  public func signOut() async throws {
    guard let authUseCase else { return }
    try await authUseCase.signOut()
  }

  public func fetchInitialData() async {
    guard let feedPostRepository else { return }

    do {
      let page: FeedPostPage = try await feedPostRepository.fetchPosts(cursor: nil, page: 20)
      self.posts = page.items
      self.nextCursor = page.nextCursor
      self.hasNext = page.hasNext
      self.state = .loaded
    } catch {
      self.state = .error(message: error.localizedDescription)
    }
  }

  public func deletePost(postID: String) async throws {
    guard let feedPostRepository else { return }
    
    try await feedPostRepository.deletePost(postID: postID)
    self.posts.removeAll { $0.id == postID }
  }
}
