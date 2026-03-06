//
//  Container+TaxiPreview.swift
//  BuddyPreviewSupport
//
//  Created by 하정우 on 3/6/26.
//

import Factory
import BuddyDomain

extension Container {
  public static func setupTaxiPreview() {
    Container.shared.authUseCase.preview { nil }
    Container.shared.userUseCase.preview { PreviewUserUseCase() }
    Container.shared.crashlyticsService.preview { PreviewCrashlyticsService() }
  }
}
