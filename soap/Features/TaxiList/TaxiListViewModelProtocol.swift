//
//  TaxiListViewModelProtocol.swift
//  soap
//
//  Created by Soongyu Kwon on 12/07/2025.
//

import Foundation

public protocol TaxiListViewModelProtocol {
  // MARK: - ViewModel Properties
  var state: TaxiListViewModel.ViewState { get set }
  var week: [Date] { get }
  var rooms: [TaxiRoom] { get }
  var locations: [TaxiLocation] { get }

  // MARK: - View Properties
  var origin: TaxiLocation? { get set }
  var destination: TaxiLocation? { get set }
  var selectedDate: Date { get set }

  var roomDepartureTime: Date { get set }
  var roomCapacity: Int { get set }

  // MARK: - Functions
  func fetchData() async
  func createRoom(title: String) async throws
}
