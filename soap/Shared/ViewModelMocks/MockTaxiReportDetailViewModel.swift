//
//  MockTaxiReportListViewModel.swift
//  soap
//
//  Created by 하정우 on 8/14/25.
//

import Foundation
import BuddyDomain

@MainActor
class MockTaxiReportDetailViewModel: TaxiReportListViewModelProtocol, Observable {
  var state: TaxiReportListViewModel.ViewState = .loading
  var reports: (incoming: [TaxiReport], outgoing: [TaxiReport]) = (incoming: [], outgoing: [])
  
  func fetchReports() async {
    // Mock implementation
  }
}
