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
  var taxiUser: TaxiUser?
  var taxiState: SettingsViewModel.ViewState = .loading
  var taxiBankName: String?
  var taxiBankNumber: String = ""
  var araAllowNSFWPosts: Bool = false
  var araAllowPoliticalPosts: Bool = false
  var araBlockedUsers: [String] = ["유능한 시조새_0b4c"]
  var otlMajor: String = "School of Computer Science"
  let otlMajorList: [String] = ["School of Computer Science", "School of Electrical Engineering", "School of Business"]
  
  func fetchTaxiUser() async {
    // Mock implementation
  }
  
  func editBankAccount(account: String) async {
    // Mock implementation
  }
  
}
