//
//  MockTaxiReportListViewModel.swift
//  soap
//
//  Created by 하정우 on 8/14/25.
//

import Foundation

@MainActor
class MockTaxiReportDetailViewModel: TaxiReportDetailViewModelProtocol, Observable {
  var state: TaxiReportListViewModel.ViewState = .loading
  var reports: (reported: [TaxiReport], reporting: [TaxiReport]) = (reported: [], reporting: [])
  
  func fetchReports() async {
    // Mock implementation
  }
}
