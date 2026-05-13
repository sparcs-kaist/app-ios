//
//  TaxiSettingsViewModelProtocol.swift
//  BuddyDomain
//
//  Created by 하정우 on 5/13/2026.
//

import SwiftUI
import Observation

@MainActor
public protocol TaxiSettingsViewModelProtocol: Observable {
  var nickname: String { get set }
  var bankName: String? { get set }
  var bankNumber: String { get set }
  var phoneNumber: String { get set }
  var showBadge: Bool { get set }
  var showAlert: Bool { get set }
  var alertContent: LocalizedStringResource { get set }
  var user: TaxiUser? { get }
  var state: TaxiSettingsViewState { get }

  func fetchUser() async
  func editInformation() async
}
