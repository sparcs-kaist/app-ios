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
  var locations: [TaxiLocation] = []

  @ObservationIgnored @Injected(
    \.taxiRoomRepository
  ) private var taxiRoomRepository: TaxiRoomRepositoryProtocol

  func fetchData() async {
    logger.debug("[TaxiListViewModel] fetching data")
    isLoading = true
    errorMessage = nil
    do {
      async let roomsTask: [TaxiRoom] = taxiRoomRepository.fetchRooms()
      async let locationsTask: [TaxiLocation] = taxiRoomRepository.fetchLocations()

      let (rooms, locations) = try await (roomsTask, locationsTask)

      self.rooms = rooms
      self.locations = locations
    } catch {
      errorMessage = error.localizedDescription
      logger.error("[TaxiListViewModel] fetch data failed: \(error.localizedDescription)")
      // TODO: HANDLE ERROR
    }
    isLoading = false
  }
}
