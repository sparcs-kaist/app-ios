//
//  MockAraSettingsViewModel.swift
//  soap
//
//  Created by 하정우 on 8/28/25.
//

import Foundation
import BuddyDomain

@Observable
class MockAraSettingsViewModel: AraSettingsViewModelProtocol {
  // MARK: - Properties
  var user: AraUser?
  var nickname: String = "유능한 시조새_0b4c"
  var nicknameUpdatable: Bool = false
  var nicknameUpdatableFrom: Date? = Calendar.current.date(byAdding: .day, value: 1, to: Date())
  var allowNSFW: Bool = false
  var allowPolitical: Bool = false
  var state: AraSettingsViewModel.ViewState = .loading
  
  // MARK: - Functions
  func fetchUser() async {
    // Mock implementation
  }
  
  func updateNickname() async throws {
    // Mock implementation
  }
  
  func updateContentPreference() async {
    // Mock implementation
  }
}
