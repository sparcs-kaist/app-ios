//
//  MockTaxiSettingsViewModel.swift
//  soap
//
//  Created by 하정우 on 8/29/25.
//

import Foundation

class MockTaxiSettingsViewModel: TaxiSettingsViewModelProtocol {
  var taxiBankName: String? = "카카오뱅크"
  var taxiBankNumber: String = "3333-01-1234567"
  var taxiUser: TaxiUser? = .mock
  var state: TaxiSettingsViewModel.ViewState = .loading
  
  func fetchTaxiUser() async {
    // Mock implementation
  }
  
  func taxiEditBankAccount(account: String) async {
    // Mock implementation
  }
}
