//
//  MockTaxiListViewModel.swift
//  soap
//
//  Created by Soongyu Kwon on 12/07/2025.
//


import SwiftUI
import Observation

@Observable
class MockTaxiListViewModel: TaxiListViewModelProtocol {
  var state: TaxiListViewModel.ViewState = .loading

  var week: [Date] {
    let calendar = Calendar.current
    return (0..<7).compactMap {
      calendar.date(byAdding: .day, value: $0, to: Date())
    }
  }

  func fetchData() async {

  }
}
