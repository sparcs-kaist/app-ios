//
//  TaxiListViewModelProtocol.swift
//  soap
//
//  Created by Soongyu Kwon on 12/07/2025.
//

import Foundation
import BuddyDomain

@MainActor
public protocol TaxiListViewModelProtocol: Observable {
  // MARK: - ViewModel Properties
  var state: TaxiListViewModel.ViewState { get }
  var week: [Date] { get }
  var rooms: [TaxiRoom] { get }
  var locations: [TaxiLocation] { get }
  var invitedRoom: TaxiRoom? { get set }

  // MARK: - View Properties
  var source: TaxiLocation? { get set }
  var destination: TaxiLocation? { get set }
  var selectedDate: Date { get set }

  var roomDepartureTime: Date { get set }
  var roomCapacity: Int { get set }

  // MARK: - Functions
  func fetchData(inviteId: String?) async
  func createRoom(title: String) async throws
}
