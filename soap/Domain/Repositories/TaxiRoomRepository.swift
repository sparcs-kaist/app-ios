//
//  TaxiRoomRepository.swift
//  soap
//
//  Created by Soongyu Kwon on 12/07/2025.
//

import Foundation
import Moya

final class TaxiRoomRepository: TaxiRoomRepositoryProtocol, @unchecked Sendable {
  private let provider: MoyaProvider<TaxiRoomTarget>

  init(provider: MoyaProvider<TaxiRoomTarget>) {
    self.provider = provider
  }

  func fetchRooms() async throws -> [TaxiRoom] {
    do {
      let response = try await provider.request(.fetchRooms)
      let result = try response.map([TaxiRoomDTO].self)
        .compactMap { $0.toModel() }

      return result
    } catch let moyaError as MoyaError {
      let body = try moyaError.response!.map(APIErrorResponse.self)
      throw body
    } catch {
      throw error
    }
  }

  func fetchLocations() async throws -> [TaxiLocation] {
    do {
      let response = try await provider.request(.fetchLocations)
      let result = try response.map(TaxiLocationResponseDTO.self)
        .locations
        .compactMap { $0.toModel() }

      return result
    } catch let moyaError as MoyaError {
      let body = try moyaError.response!.map(APIErrorResponse.self)
      throw body
    } catch {
      throw error
    }
  }

  func createRoom(with: TaxiCreateRoom) async throws -> TaxiRoom {
    do {
      let requestDTO = TaxiCreateRoomRequestDTO.fromModel(with)
      let response = try await provider.request(.createRoom(with: requestDTO))
      let result = try response.map(TaxiRoomDTO.self).toModel()

      return result
    } catch let moyaError as MoyaError {
      let body = try moyaError.response!.map(APIErrorResponse.self)
      throw body
    } catch {
      throw error
    }
  }

  func joinRoom(id: String) async throws -> TaxiRoom {
    do {
      let response = try await provider.request(.joinRoom(id: id))
      let result = try response.map(TaxiRoomDTO.self).toModel()

      return result
    } catch let moyaError as MoyaError {
      let body = try moyaError.response!.map(APIErrorResponse.self)
      throw body
    } catch {
      throw error
    }
  }
}
