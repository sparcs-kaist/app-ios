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
  var rooms: [TaxiRoom] = TaxiRoom.mockList
  var locations: [TaxiLocation] = TaxiLocation.mockList

  var origin: TaxiLocation? = nil
  var destination: TaxiLocation? = nil
  var selectedDate: Date = Date()

  var roomDepartureTime: Date = Date().ceilToNextTenMinutes()
  var roomCapacity: Int = 4

  func fetchData() async {

  }

  func createRoom(title: String) async throws {

  }
}
