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
  var taxiBankName: String?
  var taxiBankNumber: String = ""
  var otlMajor: String = "School of Computer Science"
  let otlMajorList: [String] = ["School of Computer Science", "School of Electrical Engineering", "School of Business"]
  var state: SettingsViewModel.ViewState = .loading
  
  func fetchTaxiUser() async {
    // Mock implementation
  }
  
  func taxiEditBankAccount(account: String) async {
    // Mock implementation
  }
  
}
