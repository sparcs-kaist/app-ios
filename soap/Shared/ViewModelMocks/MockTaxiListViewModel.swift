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

  func fetchData() async {

  }
}
