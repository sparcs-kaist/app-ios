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

  // MARK: - ViewModel Properties
  public var state: ViewState = .loading
  public var week: [Date] {
    let calendar = Calendar.current
    return (0..<7).compactMap {
      calendar.date(byAdding: .day, value: $0, to: Date())
    }
  }
  public var rooms: [TaxiRoom] = []
  public var locations: [TaxiLocation] = []

  // MARK: - View Properties
  public var origin: TaxiLocation?
  public var destination: TaxiLocation?
  public var selectedDate: Date = Date()

  // Room Creation
  public var roomDepartureTime: Date = Date().ceilToNextTenMinutes()
  public var roomCapacity: Int = 4

  // MARK: - Dependency
  @ObservationIgnored @Injected(
    \.taxiRoomRepository
  ) private var taxiRoomRepository: TaxiRoomRepositoryProtocol

  // MARK: - Functions
  public func fetchData() async {
    logger.debug("[TaxiListViewModel] fetching data")
    do {
      async let roomsTask: [TaxiRoom] = taxiRoomRepository.fetchRooms()
      async let locationsTask: [TaxiLocation] = taxiRoomRepository.fetchLocations()

      (rooms, locations) = try await (roomsTask, locationsTask)

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
