//
//  FeedUserRepository.swift
//  soap
//
//  Created by Soongyu Kwon on 17/08/2025.
//

import Foundation

@preconcurrency
import Moya

protocol FeedUserRepositoryProtocol: Sendable {
  func register(ssoInfo: String) async throws
}

final class FeedUserRepository: FeedUserRepositoryProtocol, Sendable {
  private let provider: MoyaProvider<FeedUserTarget>

  init(provider: MoyaProvider<FeedUserTarget>) {
    self.provider = provider
  }

  func register(ssoInfo: String) async throws {
    let response = try await provider.request(.register(ssoInfo: ssoInfo))
    _ = try response.filterSuccessfulStatusCodes()
  }
}
