//
//  MockTaxiChatListViewModel.swift
//  soap
//
//  Created by Soongyu Kwon on 14/07/2025.
//

import SwiftUI
import Observation

@Observable
class MockTaxiChatListViewModel: TaxiChatListViewModelProtocol {
  // MARK: - ViewModel Properties
  var state: TaxiChatListViewModel.ViewState = .loading
  var onGoingRooms: [TaxiRoom] = []
  var doneRooms: [TaxiRoom] = []

  // MARK: - Functions
  func fetchData() async {
  }
}
