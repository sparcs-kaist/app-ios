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
import BuddyFeedCore
import os

private let logger = Logger(subsystem: "org.sparcs.soap", category: "FeedViewModel")

@MainActor
@Observable
public final class FeedViewModel: FeedViewModelProtocol {
  // MARK: - Properties
  private var core = FeedViewModelCore()

  public var state: FeedViewState {
    switch core.phase {
    case .loading:
      .loading
    case .loaded:
      .loaded
    case .error:
      .error(message: core.errorMessage ?? "Unexpected Error")
    }
  }

  public var posts: [FeedPost] {
    get { core.posts }
    set { core.posts = newValue }
  }

  public var alertState: AlertState? = nil
  public var isAlertPresented: Bool = false
  public var isLoadingMore: Bool { core.isLoadingMore }

  public init() {}

  // MARK: - Dependencies
  @ObservationIgnored @Injected(\.feedPostUseCase) private var feedPostUseCase: FeedPostUseCaseProtocol?
  @ObservationIgnored @Injected(
    \.analyticsService
  ) private var analyticsService: AnalyticsServiceProtocol?

  // MARK: - Functions
  public func fetchInitialData() async {
    guard let request = core.beginInitialLoad() else { return }
    await fetch(request)
  }

  public func loadNextPage() async {
    guard let request = core.beginNextPage() else { return }
    await fetch(
      request,
      alertTitle: String(localized: "Unable to load more posts.", bundle: .module)
    )
  }

  private func fetch(_ request: FeedPageRequest, alertTitle: String? = nil) async {
    guard let feedPostUseCase else { return }
    do {
      let page = try await feedPostUseCase.fetchPosts(
        cursor: request.cursor,
        page: request.limit
      )
      core.receive(page, for: request.intent)
    } catch {
      logger.error("Failed to fetch feed: \(error.localizedDescription, privacy: .public)")
      core.failPage(request.intent, message: error.localizedDescription)
      if let alertTitle, core.notice != nil {
        alertState = .init(title: alertTitle, message: error.localizedDescription)
        isAlertPresented = true
      }
    }
  }

  public func deletePost(postID: String) async {
    guard let feedPostUseCase else { return }

    do {
      try await feedPostUseCase.deletePost(postID: postID)
      core.removePost(id: postID)
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
    guard let request = core.beginRefresh() else { return }
    await fetch(
      request,
      alertTitle: String(localized: "Unable to load more posts.", bundle: .module)
    )
    analyticsService?.logEvent(FeedViewEvent.feedRefreshed)
  }

  public func writeFeedButtonTapped() {
    analyticsService?.logEvent(FeedViewEvent.writeFeedButtonTapped)
  }
}
