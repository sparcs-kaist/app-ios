//
//  TaxiRoomRepository.swift
//  soap
//
//  Created by Soongyu Kwon on 12/07/2025.
//

import Foundation
import BuddyDomain

@preconcurrency
import Moya

public final class TaxiRoomRepository: TaxiRoomRepositoryProtocol, Sendable {
  private let provider: MoyaProvider<TaxiRoomTarget>

  public init(provider: MoyaProvider<TaxiRoomTarget>) {
    self.provider = provider
  }

  /// Performs a request and decodes the response, mapping `MoyaError` to the
  /// app's API error. Non-Moya errors propagate unchanged.
  private func request<T>(
    _ target: TaxiRoomTarget,
    decode: (Response) throws -> T
  ) async throws -> T {
    do {
      let response = try await provider.request(target)
      return try decode(response)
    } catch let moyaError as MoyaError {
      throw moyaError.toAPIError
    }
  }

  public func fetchRooms() async throws -> [TaxiRoom] {
    try await request(.fetchRooms) { response in
      try response.map([TaxiRoomDTO].self).compactMap { $0.toModel() }
    }
  }

  public func fetchMyRooms() async throws -> (onGoing: [TaxiRoom], done: [TaxiRoom]) {
    try await request(.fetchMyRooms) { response in
      let result = try response.map(TaxiMyRoomsResponseDTO.self)
      return (
        onGoing: result.onGoing.compactMap { $0.toModel() },
        done: result.done.compactMap { $0.toModel() }
      )
    }
  }

  public func fetchLocations() async throws -> [TaxiLocation] {
    try await request(.fetchLocations) { response in
      try response.map(TaxiLocationResponseDTO.self).locations.compactMap { $0.toModel() }
    }
  }

  public func createRoom(with: TaxiCreateRoom) async throws -> TaxiRoom {
    try await request(.createRoom(with: TaxiCreateRoomRequestDTO.fromModel(with))) { response in
      try response.map(TaxiRoomDTO.self).toModel()
    }
  }

  public func joinRoom(id: String) async throws -> TaxiRoom {
    try await request(.joinRoom(roomID: id)) { response in
      try response.map(TaxiRoomDTO.self).toModel()
    }
  }

  public func leaveRoom(id: String) async throws -> TaxiRoom {
    try await request(.leaveRoom(roomID: id)) { response in
      try response.map(TaxiRoomDTO.self).toModel()
    }
  }

  public func getRoom(id: String) async throws -> TaxiRoom {
    try await request(.getRoom(roomID: id)) { response in
      try response.map(TaxiRoomDTO.self).toModel()
    }
  }

  public func getPublicRoom(id: String) async throws -> TaxiRoom {
    try await request(.getPublicRoom(roomID: id)) { response in
      try response.map(TaxiRoomDTO.self).toModel()
    }
  }

  public func commitSettlement(id: String) async throws -> TaxiRoom {
    try await request(.commitSettlement(roomID: id)) { response in
      try response.map(TaxiRoomDTO.self).toModel()
    }
  }

  public func commitPayment(id: String) async throws -> TaxiRoom {
    try await request(.commitPayment(roomID: id)) { response in
      try response.map(TaxiRoomDTO.self).toModel()
    }
  }

  public func updateArrival(id: String, isArrived: Bool) async throws -> TaxiRoom {
    try await request(.updateArrival(roomID: id, isArrived: isArrived)) { response in
      try response.map(TaxiRoomDTO.self).toModel()
    }
  }

  public func updateCarrier(id: String, hasCarrier: Bool) async throws -> TaxiRoom {
    try await request(.updateCarrier(roomID: id, hasCarrier: hasCarrier)) { response in
      try response.map(TaxiRoomDTO.self).toModel()
    }
  }
}
