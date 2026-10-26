//
//  BuddyFeaturePostTests.swift
//  BuddyFeature
//
//  Created by Codex on 13/02/2026.
//

import Testing
import BuddyTestSupport
import Factory

/// Every Post suite nests in here: they register mocks on the shared container (and some use
/// `UserDefaults`), so they run one at a time rather than racing each other.
@Suite(.serialized)
@MainActor
struct PostFeatureTests { }

/// Registers all required dependencies for Post tests.
@MainActor
public func setupPostTestDependencies(
  araBoardUseCase: MockAraBoardUseCase? = nil,
  araCommentUseCase: MockAraCommentUseCase? = nil,
  foundationModelsUseCase: MockFoundationModelsUseCase? = nil,
  araUserRepository: MockAraUserRepository? = nil
) {
  Container.shared.analyticsService.register { MockAnalyticsService() }
  Container.shared.araBoardUseCase.register { araBoardUseCase ?? MockAraBoardUseCase() }
  Container.shared.araCommentUseCase.register { araCommentUseCase ?? MockAraCommentUseCase() }
  Container.shared.foundationModelsUseCase.register { foundationModelsUseCase ?? MockFoundationModelsUseCase() }
  Container.shared.araUserRepository.register { araUserRepository ?? MockAraUserRepository() }
}

@MainActor
public func tearDownPostTestDependencies() {
  Container.shared.araBoardUseCase.reset()
  Container.shared.araCommentUseCase.reset()
  Container.shared.foundationModelsUseCase.reset()
  Container.shared.araUserRepository.reset()
  Container.shared.analyticsService.reset()
}
