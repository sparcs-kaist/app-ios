//
//  TaxiPreviewViewModel.swift
//  soap
//
//  Created by Soongyu Kwon on 13/07/2025.
//

import SwiftUI
import MapKit
import Observation
import Factory
import BuddyDomain

@MainActor
@Observable
class TaxiPreviewViewModel {
  // MARK: - Properties
  var taxiUser: TaxiUser?
  var taxiRooms: (onGoing: [TaxiRoom], done: [TaxiRoom])?
  var roomCount: Int?

  // MARK: - Dependencies
  @ObservationIgnored @Injected(
    \.taxiRoomRepository
  ) private var taxiRoomRepository: TaxiRoomRepositoryProtocol
  @ObservationIgnored @Injected(\.userUseCase) private var userUseCase: UserUseCaseProtocol

  //MARK: - Initialiser
  init() {
    Task {
      await fetchTaxiUser()
      taxiRooms = try? await taxiRoomRepository.fetchMyRooms()
      roomCount = taxiRooms?.onGoing.count
    }
  }

  var isNotPaid: Bool {
    guard let user = taxiUser else { return true }
    guard let room = taxiRooms else { return true }
    
    // room.participants.first(where: { $0.id == taxiUser.oid })?.isSettlement ?? .notDeparted
    return !(room.onGoing.filter { room in
      room.participants.first(where: { $0.id == user.oid })?.isSettlement == .paymentRequired
    }.isEmpty)
  }
  
  func isJoined(participants: [TaxiParticipant]) -> Bool {
    return participants.first(where: { $0.id == taxiUser?.oid }) != nil
  }

  func calculateRoute(source: CLLocationCoordinate2D, destination: CLLocationCoordinate2D) async throws -> MKRoute {
    let request = MKDirections.Request()
    let sourceLocation = CLLocation(latitude: source.latitude, longitude: source.longitude)
    let destinationLocation = CLLocation(latitude: destination.latitude, longitude: destination.longitude)
    request.source = MKMapItem(location: sourceLocation, address: nil)
    request.destination = MKMapItem(location: destinationLocation, address: nil)
    request.transportType = .automobile

    let directions = MKDirections(request: request)
    let response = try await directions.calculate()
    guard let route = response.routes.first else {
      throw NSError(domain: "No route found", code: -1)
    }
    return route
  }

  func joinRoom(id: String) async throws {
    let _ = try await taxiRoomRepository.joinRoom(id: id)
  }

  private func fetchTaxiUser() async {
    self.taxiUser = await userUseCase.taxiUser
  }
}
