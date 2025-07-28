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

  private var userStorage: Factory<UserStorageProtocol> {
    self { UserStorage() }.singleton
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

  var taxiChatRepository: Factory<TaxiChatRepositoryProtocol> {
    self {
      TaxiChatRepository(
        provider: MoyaProvider<TaxiChatTarget>(plugins: [self.authPlugin.resolve()])
      )
    }
  }

  // MARK: - Services
  private var authenticationService: Factory<AuthenticationServiceProtocol> {
    self {
      MainActor.assumeIsolated {
        AuthenticationService(provider: MoyaProvider<AuthTarget>())
      }
    }.singleton
  }

  private var taxiChatService: Factory<TaxiChatServiceProtocol> {
    self {
      TaxiChatService(tokenStorage: self.tokenStorage.resolve())
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

  var userUseCase: Factory<UserUseCaseProtocol> {
    self {
      UserUseCase(
        taxiUserRepository: self.taxiUserRepository.resolve(),
        userStorage: self.userStorage.resolve()
      )
    }.singleton
  }

  @MainActor
  var taxiChatUseCase: ParameterFactory<TaxiRoom, TaxiChatUseCaseProtocol> {
    self {
      @MainActor in TaxiChatUseCase(
        taxiChatService: self.taxiChatService.resolve(),
        userUseCase: self.userUseCase.resolve(),
        taxiChatRepository: self.taxiChatRepository.resolve(),
        room: $0
      )
    }
  }
}
