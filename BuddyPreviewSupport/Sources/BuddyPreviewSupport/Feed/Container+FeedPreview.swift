//
//  Container+FeedPreview.swift
//  BuddyPreviewSupport
//

import Factory
import BuddyDomain

extension Container {
  public static func setupFeedPreview() {
    Container.shared.feedPostUseCase.preview { PreviewFeedPostUseCase() }
    Container.shared.feedCommentUseCase.preview { PreviewFeedCommentUseCase() }
    Container.shared.authUseCase.preview { nil }
    Container.shared.userUseCase.preview { PreviewUserUseCase() }
    Container.shared.crashlyticsService.preview { PreviewCrashlyticsService() }
    Container.shared.feedImageUseCase.preview { nil }
  }
}
