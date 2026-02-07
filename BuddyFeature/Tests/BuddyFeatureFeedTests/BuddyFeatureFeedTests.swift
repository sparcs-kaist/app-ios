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
  feedCommentUseCase: MockFeedCommentUseCase? = nil,
  authUseCase: MockAuthUseCase? = nil
) {
  // Always register crashlytics service (required by ViewModels)
  Container.shared.crashlyticsService.register { MockCrashlyticsService() }

  // Register provided mocks, or default mocks for promised factories
  Container.shared.feedPostUseCase.register { feedPostUseCase ?? MockFeedPostUseCase() }
  Container.shared.feedCommentUseCase.register { feedCommentUseCase ?? MockFeedCommentUseCase() }
  Container.shared.authUseCase.register { authUseCase ?? MockAuthUseCase() }
}

@MainActor
public func tearDownFeedTestDependencies() {
  Container.shared.feedPostUseCase.reset()
  Container.shared.feedCommentUseCase.reset()
  Container.shared.authUseCase.reset()
  Container.shared.crashlyticsService.reset()
}
