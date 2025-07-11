//
//  Container.swift
//  soap
//
//  Created by Soongyu Kwon on 09/07/2025.
//

import Foundation
import Factory
import Moya

extension Container {
  // MARK: - Storage
  private var tokenStorage: Factory<TokenStorageProtocol> {
    self { TokenStorage() }.singleton
  }

  // MARK: - Networking
  private var authProvider: Factory<MoyaProvider<AuthTarget>> {
    self { MoyaProvider<AuthTarget>() }
  }

  private var taxiRoomProvider: Factory<MoyaProvider<TaxiRoomTarget>> {
    self { MoyaProvider<TaxiRoomTarget>() }
  }

  // MARK: - Repositories
  var taxiRoomRepository: Factory<TaxiRoomRepositoryProtocol> {
    self { TaxiRoomRepository(provider: self.taxiRoomProvider.resolve()) }
  }

  // MARK: - Services
  private var authenticationService: Factory<AuthenticationServiceProtocol> {
    self {
      MainActor.assumeIsolated {
        AuthenticationService(provider: self.authProvider.resolve())
      }
    }.singleton
  }

  // MARK: - Use Cases
  var authUseCase: Factory<AuthUseCaseProtocol> {
    self {
      AuthUseCase(
        authenticationService: self.authenticationService.resolve(),
        tokenStorage: self.tokenStorage.resolve()
      )
    }.singleton
  }
}
