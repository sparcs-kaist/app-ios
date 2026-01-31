//
//  TaxiListViewModel.swift
//  soap
//
//  Created by Soongyu Kwon on 12/07/2025.
//

import SwiftUI
import Observation
import Factory
import BuddyDomain

@Observable
public class TaxiListViewModel: TaxiListViewModelProtocol {
  public enum ViewState {
    case loading
    case loaded(rooms: [TaxiRoom], locations: [TaxiLocation])
    case empty
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
  public var invitedRoom: TaxiRoom?

  // MARK: - View Properties
  public var source: TaxiLocation?
  public var destination: TaxiLocation?
  public var selectedDate: Date = Date()

  // Room Creation
  public var roomDepartureTime: Date = Date().ceilToNextTenMinutes()
  public var roomCapacity: Int = 4

  public init() { }

  // MARK: - Dependency
  @ObservationIgnored @Injected(\.taxiRoomRepository) private var taxiRoomRepository: TaxiRoomRepositoryProtocol?
  @ObservationIgnored @Injected(\.taxiLocationUseCase) private var taxiLocationUseCase: TaxiLocationUseCaseProtocol?

  // MARK: - Functions
  public func fetchData(inviteId: String? = nil) async {
    guard let taxiRoomRepository, let taxiLocationUseCase else { return }

    do {
      let repo = taxiRoomRepository
      self.rooms = try await repo.fetchRooms()
      try await taxiLocationUseCase.fetchLocations()
      self.locations = await taxiLocationUseCase.locations
      if let inviteId = inviteId {
        invitedRoom = rooms.first(where: { $0.id == inviteId })
      }

      withAnimation(.spring) {
        if rooms.isEmpty {
          state = .empty
          return
        }

        state = .loaded(rooms: rooms, locations: self.locations)
      }
    } catch {
      withAnimation(.spring) {
        state = .error(message: error.localizedDescription)
      }
    }
  }

  public func createRoom(title: String) async throws {
    guard let taxiRoomRepository else { return }

    // Safely capture values before any suspension
    guard let source = source, let destination = destination else { return }
    let departureTime = roomDepartureTime
    let capacity = roomCapacity

    let requestModel = TaxiCreateRoom(
      title: title,
      source: source,
      destination: destination,
      departureTime: departureTime,
      capacity: capacity
    )

    let _ = try await taxiRoomRepository.createRoom(with: requestModel)
  }
}
