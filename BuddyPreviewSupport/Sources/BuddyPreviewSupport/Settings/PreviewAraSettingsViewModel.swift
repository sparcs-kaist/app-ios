//
//  PreviewAraSettingsViewModel.swift
//  BuddyPreviewSupport
//
//  Created by 하정우 on 5/13/2026.
//

import Foundation
import Observation
import BuddyDomain

@Observable
@MainActor
public final class PreviewAraSettingsViewModel: AraSettingsViewModelProtocol {
  public var user: AraUser?
  public var allowNSFW: Bool
  public var allowPolitical: Bool
  public var nickname: String
  public var state: AraSettingsViewState

  public var nicknameUpdatable: Bool {
    guard let nicknameUpdatableFrom else { return true }
    return nicknameUpdatableFrom <= Date()
  }

  public var nicknameUpdatableFrom: Date? {
    guard let nicknameUpdatedAt = user?.nicknameUpdatedAt else { return nil }
    return Calendar.current.date(byAdding: .month, value: 3, to: nicknameUpdatedAt)
  }

  public init(state: AraSettingsViewState = .loaded) {
    let previewUser = AraUser(
      id: 984,
      nickname: "오열하는 운영체제 및 실험",
      nicknameUpdatedAt: Calendar.current.date(byAdding: .month, value: -4, to: Date()),
      allowNSFW: false,
      allowPolitical: true
    )
    self.user = previewUser
    self.allowNSFW = previewUser.allowNSFW
    self.allowPolitical = previewUser.allowPolitical
    self.nickname = previewUser.nickname
    self.state = state
  }

  public func fetchUser() async {}
  public func updateNickname() async throws {}
  public func updateContentPreference() async {}
}
