//
//  MockTaxiSettingsViewModel.swift
//  soap
//
//  Created by 하정우 on 8/29/25.
//

import Foundation
import BuddyDomain

class MockTaxiSettingsViewModel: TaxiSettingsViewModelProtocol {
  var bankName: String? = "카카오뱅크"
  var bankNumber: String = "3333-01-1234567"
  var phoneNumber: String = "010-1234-5678"
  var showBadge: Bool = true
  var user: TaxiUser? = .mock
  var state: TaxiSettingsViewModel.ViewState = .loading
  
  func fetchUser() async {
    // Mock implementation
  }
  
  func editInformation() async {
    // Mock implementation
  }
}
