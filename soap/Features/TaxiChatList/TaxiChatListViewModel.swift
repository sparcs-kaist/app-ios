//
//  TaxiChatListViewModel.swift
//  soap
//
//  Created by Soongyu Kwon on 13/07/2025.
//

import SwiftUI
import Observation
import Factory

@Observable
class TaxiChatListViewModel: TaxiChatListViewModelProtocol {
  enum ViewState {
    case loading
    case loaded(onGoing: [TaxiRoom], done: [TaxiRoom])
    case error(message: String)
  }
  // MARK: - ViewModel Properties
  var state: ViewState = .loading
  var onGoingRooms: [TaxiRoom] = []
  var doneRooms: [TaxiRoom] = []

  // MARK: - Dependency
  @ObservationIgnored @Injected(
    \.taxiRoomRepository
  ) private var taxiRoomRepository: TaxiRoomRepositoryProtocol

  // MARK: - Functions
  func fetchData() async {
    do {
      (onGoingRooms, doneRooms) = try await taxiRoomRepository.fetchMyRooms()
      withAnimation(.spring) {
        state = .loaded(onGoing: onGoingRooms, done: doneRooms)
      }
    } catch {
      withAnimation(.spring) {
        state = .error(message: error.localizedDescription)
      }
    }
  }
}
