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
  func fetchBoards() async throws -> [AraBoard]
  func fetchPosts(boardID: Int, page: Int) async throws -> AraPostPage
}

actor AraBoardRepository: AraBoardRepositoryProtocol {
  private let provider: MoyaProvider<AraBoardTarget>

  // MARK: - Caches
  private var cachedBoards: [AraBoard]? = nil

  init(provider: MoyaProvider<AraBoardTarget>) {
    self.provider = provider
  }

  func fetchBoards() async throws -> [AraBoard] {
    if let cachedBoards {
      return cachedBoards
    }

    let response = try await provider.request(.fetchBoards)
    let boards: [AraBoard] = try response.map([AraBoardDTO].self).compactMap { $0.toModel() }

    self.cachedBoards = boards
    return boards
  }

  func fetchPosts(boardID: Int, page: Int) async throws -> AraPostPage {
    let response = try await provider.request(.fetchPosts(boardID: boardID, page: page))
    let page: AraPostPage = try response.map(AraPostPageDTO.self).toModel()

    return page
  }
}
