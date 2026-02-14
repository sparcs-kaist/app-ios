//
//  BuddyFeaturePostTests.swift
//  BuddyFeature
//
//  Created by Codex on 13/02/2026.
//

import BuddyTestSupport
import Factory

/// Registers all required dependencies for Post tests.
@MainActor
public func setupPostTestDependencies(
  araBoardUseCase: MockAraBoardUseCase? = nil,
  araCommentUseCase: MockAraCommentUseCase? = nil,
  foundationModelsUseCase: MockFoundationModelsUseCase? = nil
) {
  Container.shared.analyticsService.register { MockAnalyticsService() }
  Container.shared.araBoardUseCase.register { araBoardUseCase ?? MockAraBoardUseCase() }
  Container.shared.araCommentUseCase.register { araCommentUseCase ?? MockAraCommentUseCase() }
  Container.shared.foundationModelsUseCase.register { foundationModelsUseCase ?? MockFoundationModelsUseCase() }
}

@MainActor
public func tearDownPostTestDependencies() {
  Container.shared.araBoardUseCase.reset()
  Container.shared.araCommentUseCase.reset()
  Container.shared.foundationModelsUseCase.reset()
  Container.shared.analyticsService.reset()
}
