//
//  AraBoardRepository.swift
//  soap
//
//  Created by Soongyu Kwon on 05/08/2025.
//

import Foundation

@preconcurrency
import Moya

protocol AraBoardRepositoryProtocol {
  func getBoards() async throws -> [AraBoard]
}

final class AraBoardRepository: AraBoardRepositoryProtocol, Sendable {
  private let provider: MoyaProvider<AraBoardTarget>

  init(provider: MoyaProvider<AraBoardTarget>) {
    self.provider = provider
  }

  func getBoards() async throws -> [AraBoard] {
    let response = try await provider.request(.getBoards)
    let boards: [AraBoard] = try response.map([AraBoardDTO].self).compactMap { $0.toModel() }

    return boards
  }
}
