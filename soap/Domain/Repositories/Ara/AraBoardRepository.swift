//
//  AraBoardRepository.swift
//  soap
//
//  Created by Soongyu Kwon on 05/08/2025.
//

import Foundation

@preconcurrency
import Moya

protocol AraBoardRepositoryProtocol: Sendable {
  func getBoards() async throws -> [AraBoard]
}

actor AraBoardRepository: AraBoardRepositoryProtocol {
  private let provider: MoyaProvider<AraBoardTarget>

  // MARK: - Caches
  private var cachedBoards: [AraBoard]? = nil

  init(provider: MoyaProvider<AraBoardTarget>) {
    self.provider = provider
  }

  func getBoards() async throws -> [AraBoard] {
    if let cachedBoards {
      return cachedBoards
    }

    let response = try await provider.request(.getBoards)
    let boards: [AraBoard] = try response.map([AraBoardDTO].self).compactMap { $0.toModel() }

    self.cachedBoards = boards
    return boards
  }
}
