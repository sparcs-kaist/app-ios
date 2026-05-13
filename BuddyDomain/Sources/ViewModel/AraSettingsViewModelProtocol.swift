//
//  AraSettingsViewModelProtocol.swift
//  BuddyDomain
//
//  Created by 하정우 on 5/13/2026.
//

import Foundation
import Observation

@MainActor
public protocol AraSettingsViewModelProtocol: Observable {
  var user: AraUser? { get }
  var allowNSFW: Bool { get set }
  var allowPolitical: Bool { get set }
  var nickname: String { get set }
  var nicknameUpdatable: Bool { get }
  var nicknameUpdatableFrom: Date? { get }
  var state: AraSettingsViewState { get }

  func fetchUser() async
  func updateNickname() async throws
  func updateContentPreference() async
}
