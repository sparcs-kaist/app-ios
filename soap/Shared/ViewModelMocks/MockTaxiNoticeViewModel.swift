//
//  MockTaxiNoticeViewModel.swift
//  soap
//
//  Created by 하정우 on 8/14/25.
//

import Foundation

@MainActor
class MockTaxiNoticeViewModel: TaxiNoticeViewModelProtocol, Observable {
  var notices: [TaxiNotice] = []
  var state: TaxiNoticeViewModel.ViewState = .loading
  
  func fetchNotices() async {
    // Mock implementation
  }
}
