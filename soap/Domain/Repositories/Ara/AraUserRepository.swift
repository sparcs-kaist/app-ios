//
//  AraUserRepository.swift
//  soap
//
//  Created by Soongyu Kwon on 01/08/2025.
//

import Foundation

@preconcurrency
import Moya

protocol AraUserRepositoryProtocol: Sendable {
  func register(ssoInfo: String) async throws
}

final class AraUserRepository: AraUserRepositoryProtocol, Sendable {
  private let provider: MoyaProvider<AraUserTarget>

  init(provider: MoyaProvider<AraUserTarget>) {
    self.provider = provider
  }

  func register(ssoInfo: String) async throws {
    let response = try await provider.request(.register(ssoInfo: ssoInfo))
    let _ = try response.filterSuccessfulStatusCodes()
  }
}
