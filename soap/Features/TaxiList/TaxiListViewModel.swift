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
public class TaxiListViewModel: TaxiListViewModelProtocol {
  public enum ViewState {
    case loading
    case loaded(rooms: [TaxiRoom], locations: [TaxiLocation])
    case empty(locations: [TaxiLocation])
    case error(message: String)
  }

  public var state: ViewState = .loading

  @ObservationIgnored @Injected(
    \.taxiRoomRepository
  ) private var taxiRoomRepository: TaxiRoomRepositoryProtocol

  public func fetchData() async {
    logger.debug("[TaxiListViewModel] fetching data")
    do {
      async let roomsTask: [TaxiRoom] = taxiRoomRepository.fetchRooms()
      async let locationsTask: [TaxiLocation] = taxiRoomRepository.fetchLocations()

      let (rooms, locations) = try await (roomsTask, locationsTask)

      withAnimation(.spring) {
        if rooms.isEmpty {
          state = .empty(locations: locations)
          return
        }

        state = .loaded(rooms: rooms, locations: locations)
      }
    } catch {
      logger.error("[TaxiListViewModel] fetch data failed: \(error.localizedDescription)")
      withAnimation(.spring) {
        state = .error(message: error.localizedDescription)
      }
      // TODO: HANDLE ERROR
    }
  }
}
