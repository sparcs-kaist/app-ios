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
  
  public func fetchRooms() async throws -> [TaxiRoom] {
    do {
      let response = try await provider.request(.fetchRooms)
      let result = try response.map([TaxiRoomDTO].self)
        .compactMap { $0.toModel() }

      return result
    } catch let moyaError as MoyaError {
      throw moyaError.toAPIError
    } catch {
      throw error
    }
  }

  public func fetchMyRooms() async throws -> (onGoing: [TaxiRoom], done: [TaxiRoom]) {
    do {
      let response = try await provider.request(.fetchMyRooms)
      let result = try response.map(TaxiMyRoomsResponseDTO.self)

      let onGoingRooms: [TaxiRoom] = result.onGoing.compactMap { $0.toModel() }
      let doneRooms: [TaxiRoom] = result.done.compactMap { $0.toModel() }

      return (onGoing: onGoingRooms, done: doneRooms)
    } catch let moyaError as MoyaError {
      throw moyaError.toAPIError
    } catch {
      throw error
    }
  }

  public func fetchLocations() async throws -> [TaxiLocation] {
    do {
      let response = try await provider.request(.fetchLocations)
      let result = try response.map(TaxiLocationResponseDTO.self)
        .locations
        .compactMap { $0.toModel() }

      return result
    } catch let moyaError as MoyaError {
      throw moyaError.toAPIError
    } catch {
      throw error
    }
  }

  public func createRoom(with: TaxiCreateRoom) async throws -> TaxiRoom {
    do {
      let requestDTO = TaxiCreateRoomRequestDTO.fromModel(with)
      let response = try await provider.request(.createRoom(with: requestDTO))
      let result = try response.map(TaxiRoomDTO.self).toModel()

      return result
    } catch let moyaError as MoyaError {
      throw moyaError.toAPIError
    } catch {
      throw error
    }
  }

  public func joinRoom(id: String) async throws -> TaxiRoom {
    do {
      let response = try await provider.request(.joinRoom(roomID: id))
      let result = try response.map(TaxiRoomDTO.self).toModel()

      return result
    } catch let moyaError as MoyaError {
      throw moyaError.toAPIError
    } catch {
      throw error
    }
  }

  public func leaveRoom(id: String) async throws -> TaxiRoom {
    do {
      let response = try await provider.request(.leaveRoom(roomID: id))
      let result = try response.map(TaxiRoomDTO.self).toModel()

      return result
    } catch let moyaError as MoyaError {
      throw moyaError.toAPIError
    } catch {
      throw error
    }
  }

  public func getRoom(id: String) async throws -> TaxiRoom {
    do {
      let response = try await provider.request(.getRoom(roomID: id))
      let result = try response.map(TaxiRoomDTO.self).toModel()

      return result
    } catch let moyaError as MoyaError {
      throw moyaError.toAPIError
    } catch {
      throw error
    }
  }

  public func commitSettlement(id: String) async throws -> TaxiRoom {
    do {
      let response = try await provider.request(.commitSettlement(roomID: id))
      let result = try response.map(TaxiRoomDTO.self).toModel()

      return result
    } catch let moyaError as MoyaError {
      throw moyaError.toAPIError
    } catch {
      throw error
    }
  }

  public func commitPayment(id: String) async throws -> TaxiRoom {
    do {
      let response = try await provider.request(.commitPayment(roomID: id))
      let result = try response.map(TaxiRoomDTO.self).toModel()

      return result
    } catch let moyaError as MoyaError {
      throw moyaError.toAPIError
    } catch {
      throw error
    }
  }
}
