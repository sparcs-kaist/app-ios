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
}
