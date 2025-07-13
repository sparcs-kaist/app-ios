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
  private var authPlugin: Factory<AccessTokenPlugin> {
    self {
      let tokenStorage = self.tokenStorage.resolve()
      return AccessTokenPlugin { _ in
        return tokenStorage.getAccessToken() ?? ""
      }
    }
  }

  // MARK: - Repositories
  var taxiRoomRepository: Factory<TaxiRoomRepositoryProtocol> {
    self { TaxiRoomRepository(provider: MoyaProvider<TaxiRoomTarget>(plugins: [self.authPlugin.resolve()])) }
  }

  var taxiUserRepository: Factory<TaxiUserRepositoryProtocol> {
    self { TaxiUserRepository(provider: MoyaProvider<TaxiUserTarget>(plugins: [self.authPlugin.resolve()])) }
  }

  // MARK: - Services
  private var authenticationService: Factory<AuthenticationServiceProtocol> {
    self {
      MainActor.assumeIsolated {
        AuthenticationService(provider: MoyaProvider<AuthTarget>())
      }
    }.singleton
  }

  // MARK: - Use Cases
  @MainActor
  var authUseCase: Factory<AuthUseCaseProtocol> {
    self {
      @MainActor in AuthUseCase(
        authenticationService: self.authenticationService.resolve(),
        tokenStorage: self.tokenStorage.resolve()
      )
    }.singleton
  }

  @MainActor
  var userUseCase: Factory<UserUseCaseProtocol> {
    self {
      @MainActor in UserUseCase(taxiUserRepository: self.taxiUserRepository.resolve())
    }.singleton
  }
}
