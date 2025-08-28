//
//  MockSettingsViewModel.swift
//  soap
//
//  Created by 하정우 on 8/8/25.
//

import SwiftUI

@Observable
class MockSettingsViewModel: SettingsViewModelProtocol {
  // MARK: - Properties
  var araUser: AraMe?
  var taxiUser: TaxiUser?
  var state: SettingsViewModel.ViewState = .loading
  var taxiBankName: String?
  var taxiBankNumber: String = ""
  var araNickname: String = "유능한 시조새_0b4c"
  var araNicknameUpdatable: Bool = false
  var araNicknameUpdatableSince: Date? = Calendar.current.date(byAdding: .day, value: 1, to: Date())
  var araAllowNSFWPosts: Bool = false
  var araAllowPoliticalPosts: Bool = false
  var otlMajor: String = "School of Computer Science"
  let otlMajorList: [String] = ["School of Computer Science", "School of Electrical Engineering", "School of Business"]
  
  func fetchAraUser() async {
    // Mock implementation
  }
  
  func updateAraNickname() async throws {
    // Mock implementation
  }
  
  func updateAraPostVisibility() async {
    // Mock implementation
  }
  
  func fetchTaxiUser() async {
    // Mock implementation
  }
  
  func taxiEditBankAccount(account: String) async {
    // Mock implementation
  }
  
}
