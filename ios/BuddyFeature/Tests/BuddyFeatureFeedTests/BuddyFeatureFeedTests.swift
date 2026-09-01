//
//  BuddyFeatureFeedTests.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 06/02/2026.
//

import BuddyTestSupport
import Factory

/// Registers all required dependencies for Feed tests and returns cleanup function
@MainActor
public func setupFeedTestDependencies(
  feedPostUseCase: MockFeedPostUseCase? = nil,
  feedCommentUseCase: MockFeedCommentUseCase? = nil
) {
  // Always register crashlytics service (required by ViewModels)
  Container.shared.crashlyticsService.register { MockCrashlyticsService() }
  Container.shared.analyticsService.register { MockAnalyticsService() }

  // Register provided mocks, or default mocks for promised factories
  Container.shared.feedPostUseCase.register { feedPostUseCase ?? MockFeedPostUseCase() }
  Container.shared.feedCommentUseCase.register { feedCommentUseCase ?? MockFeedCommentUseCase() }
}

@MainActor
public func tearDownFeedTestDependencies() {
  Container.shared.feedPostUseCase.reset()
  Container.shared.feedCommentUseCase.reset()
  Container.shared.crashlyticsService.reset()
  Container.shared.analyticsService.reset()
}
