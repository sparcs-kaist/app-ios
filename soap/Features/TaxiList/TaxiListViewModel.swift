//
//  TaxiListViewModel.swift
//  soap
//
//  Created by Soongyu Kwon on 12/07/2025.
//

import SwiftUI
import Observation
import Factory

@Observable
class TaxiListViewModel {
  var isLoading: Bool = false
  var errorMessage: String? = nil

  var rooms: [TaxiRoom] = []

  @ObservationIgnored @Injected(
    \.taxiRoomRepository
  ) private var taxiRoomRepository: TaxiRoomRepositoryProtocol

  func fetchData() async {
    logger.debug("[TaxiListViewModel] fetching data")
    isLoading = true
    errorMessage = nil
    do {
      let rooms: [TaxiRoom] = try await taxiRoomRepository.fetchRooms()
      logger.debug(rooms)
      self.rooms = rooms
    } catch {
      errorMessage = error.localizedDescription
      logger.error("[TaxiListViewModel] fetch data failed: \(error.localizedDescription)")
      // TODO: HANDLE ERROR
    }
    isLoading = false
  }
}
