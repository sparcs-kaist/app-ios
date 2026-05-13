//
//  PreviewTaxiSettingsViewModel.swift
//  BuddyPreviewSupport
//
//  Created by 하정우 on 5/13/2026.
//

import SwiftUI
import Observation
import BuddyDomain

@Observable
@MainActor
public final class PreviewTaxiSettingsViewModel: TaxiSettingsViewModelProtocol {
  public var nickname: String
  public var bankName: String?
  public var bankNumber: String
  public var phoneNumber: String
  public var showBadge: Bool
  public var showAlert: Bool = false
  public var alertContent: LocalizedStringResource = ""
  public var user: TaxiUser?
  public var state: TaxiSettingsViewState

  public init(state: TaxiSettingsViewState = .loaded) {
    let previewUser = TaxiUser.mock
    self.user = previewUser
    self.nickname = previewUser.nickname
    self.bankName = previewUser.account.split(separator: " ").first.map(String.init)
    self.bankNumber = previewUser.account.split(separator: " ").last.map(String.init) ?? ""
    self.phoneNumber = (previewUser.phoneNumber ?? "").filter { $0.isASCIINumber }
    self.showBadge = previewUser.badge ?? false
    self.state = state
  }

  public func fetchUser() async {}
  public func editInformation() async {}
}
