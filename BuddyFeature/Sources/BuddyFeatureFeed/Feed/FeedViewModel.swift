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
import os

private let logger = Logger(subsystem: "org.sparcs.soap", category: "FeedViewModel")

@MainActor
@Observable
public final class FeedViewModel: FeedViewModelProtocol {
  // MARK: - Properteis
  public var state: FeedViewState = .loading
  public var posts: [FeedPost] = []
  public var alertState: AlertState? = nil
  public var isAlertPresented: Bool = false

  public var isLoadingMore: Bool = false
  private var nextCursor: String? = nil
  private var hasNext: Bool = false

  public init() {}

  // MARK: - Dependencies
  @ObservationIgnored @Injected(\.feedPostUseCase) private var feedPostUseCase: FeedPostUseCaseProtocol?
  @ObservationIgnored @Injected(
    \.analyticsService
  ) private var analyticsService: AnalyticsServiceProtocol?

  // MARK: - Functions
  public func fetchInitialData() async {
    guard let feedPostUseCase else { return }

    do {
      let page: FeedPostPage = try await feedPostUseCase.fetchPosts(cursor: nil, page: 20)
      self.posts = page.items
      self.nextCursor = page.nextCursor
      self.hasNext = page.hasNext
      self.state = .loaded
    } catch {
      logger.error("Failed to fetch feed: \(error.localizedDescription, privacy: .public)")
      self.state = .error(message: error.localizedDescription)
    }
  }

  public func loadNextPage() async {
    guard !isLoadingMore && hasNext, let feedPostUseCase else { return }

    isLoadingMore = true
    defer { isLoadingMore = false }

    do {
      let page: FeedPostPage = try await feedPostUseCase.fetchPosts(cursor: nextCursor, page: 20)
      self.posts.append(contentsOf: page.items)
      self.nextCursor = page.nextCursor
      self.hasNext = page.hasNext
    } catch {
      logger.error("Failed to load more posts: \(error.localizedDescription, privacy: .public)")
      self.alertState = .init(title: String(localized: "Unable to load more posts.", bundle: .module), message: error.localizedDescription)
      self.isAlertPresented = true
    }
  }

  public func deletePost(postID: String) async {
    guard let feedPostUseCase else { return }

    do {
      try await feedPostUseCase.deletePost(postID: postID)
      self.posts.removeAll { $0.id == postID }
    } catch {
      logger.error("Failed to delete post: \(error.localizedDescription, privacy: .public)")
      self.alertState = .init(title: String(localized: "Unable to delete post.", bundle: .module), message: error.localizedDescription)
      self.isAlertPresented = true
    }
  }

  public func openSettingsTapped() {
    analyticsService?.logEvent(FeedViewEvent.openSettingsButtonTapped)
  }

  public func refreshFeed() async {
    await fetchInitialData()
    analyticsService?.logEvent(FeedViewEvent.feedRefreshed)
  }

  public func writeFeedButtonTapped() {
    analyticsService?.logEvent(FeedViewEvent.writeFeedButtonTapped)
  }
}
