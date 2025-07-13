//
//  TaxiRoomRepository.swift
//  soap
//
//  Created by Soongyu Kwon on 12/07/2025.
//

import Foundation
import Moya

class TaxiRoomRepository: TaxiRoomRepositoryProtocol {
  private let provider: MoyaProvider<TaxiRoomTarget>

  init(provider: MoyaProvider<TaxiRoomTarget>) {
    self.provider = provider
  }

  func fetchRooms() async throws -> [TaxiRoom] {
    return try await withCheckedThrowingContinuation { continuation in
      provider.request(.fetchRooms) { result in
        switch result {
        case .success(let response):
          do {
            let rooms: [TaxiRoom] = try response.map([TaxiRoomDTO].self)
              .compactMap { $0.toModel() }
            continuation.resume(returning: rooms)
          } catch {
            continuation.resume(throwing: error)
          }
        case .failure(let error):
          continuation.resume(throwing: error)
        }
      }
    }
  }

  func fetchLocations() async throws -> [TaxiLocation] {
    return try await withCheckedThrowingContinuation { continuation in
      provider.request(.fetchLocations) { result in
        switch result {
        case .success(let response):
          do {
            let locations: [TaxiLocation] = try response.map(TaxiLocationResponseDTO.self)
              .locations
              .compactMap { $0.toModel() }
            continuation.resume(returning: locations)
          } catch {
            continuation.resume(throwing: error)
          }
        case .failure(let error):
          continuation.resume(throwing: error)
        }
      }
    }
  }

  func createRoom(with: TaxiCreateRoom) async throws -> TaxiRoom {
    return try await withCheckedThrowingContinuation { continuation in
      let requestDTO = TaxiCreateRoomRequestDTO.fromModel(with)
      provider.request(.createRoom(with: requestDTO)) { result in
        switch result {
        case .success(let response):
          do {
            let room: TaxiRoom = try response.map(TaxiRoomDTO.self).toModel()
            continuation.resume(returning: room)
          } catch {
            continuation.resume(throwing: error)
          }
        case .failure(let error):
          continuation.resume(throwing: error)
        }
      }
    }
  }
}
