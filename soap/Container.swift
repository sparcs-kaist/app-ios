//
//  Container.swift
//  soap
//
//  Created by Soongyu Kwon on 09/07/2025.
//

import Foundation
import Factory
import Moya
import BuddyDomain
import BuddyDataCore
import BuddyDataiOS

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

  var authRepository: Factory<AuthRepositoryProtocol> {
    self { AuthRepository(provider: MoyaProvider<AuthTarget>()) }
  }
  
  var versionRepository: Factory<VersionRepositoryProtocol> {
    self { VersionRepository(provider: MoyaProvider<VersionTarget>()) }
  }

  // MARK: - Services
  private var authenticationService: Factory<AuthenticationServiceProtocol> {
    self {
      MainActor.assumeIsolated {
        AuthenticationService(authRepository: self.authRepository.resolve())
      }
    }.singleton
  }

  private var taxiChatService: Factory<TaxiChatServiceProtocol> {
    self {
      TaxiChatService(tokenStorage: self.tokenStorage.resolve())
    }.singleton
  }

  var sessionBridgeService: Factory<SessionBridgeServiceProtocol> {
    self {
       SessionBridgeService()
    }.singleton
  }

  var crashlyticsService: Factory<CrashlyticsServiceProtocol> {
    self { CrashlyticsService() }.singleton
  }

  // MARK: - Use Cases
  var authUseCase: Factory<AuthUseCaseProtocol> {
    self {
      AuthUseCase(
        authenticationService: self.authenticationService.resolve(),
        tokenStorage: self.tokenStorage.resolve(),
        araUserRepository: self.araUserRepository.resolve(),
        feedUserRepository: self.feedUserRepository.resolve(),
        otlUserRepository: self.otlUserRepository.resolve()
      )
    }.singleton
  }

  var userUseCase: Factory<UserUseCaseProtocol> {
    self {
      UserUseCase(
        taxiUserRepository: self.taxiUserRepository.resolve(),
        feedUserRepository: self.feedUserRepository.resolve(),
        araUserRepository: self.araUserRepository.resolve(),
        otlUserRepository: self.otlUserRepository.resolve(),
        userStorage: self.userStorage.resolve()
      )
    }.singleton
  }

  var taxiChatUseCase: ParameterFactory<TaxiRoom, TaxiChatUseCaseProtocol> {
    self {
      TaxiChatUseCase(
        taxiChatService: self.taxiChatService.resolve(),
        userUseCase: self.userUseCase.resolve(),
        taxiChatRepository: self.taxiChatRepository.resolve(),
        taxiRoomRepository: self.taxiRoomRepository.resolve(),
        room: $0
      )
    }
  }

  var taxiLocationUseCase: Factory<TaxiLocationUseCaseProtocol> {
    self {
      TaxiLocationUseCase(taxiRoomRepository: self.taxiRoomRepository.resolve())
    }
  }
  
  var taxiRoomUseCase: Factory<TaxiRoomUseCaseProtocol> {
    self {
      TaxiRoomUseCase(
        taxiRoomRepository: self.taxiRoomRepository.resolve(),
        userStorage: self.userStorage.resolve()
      )
    }
  }

  var foundationModelsUseCase: Factory<FoundationModelsUseCaseProtocol> {
    self {
      FoundationModelsUseCase()
    }
  }
  
  var timetableUseCase: Factory<TimetableUseCaseProtocol> {
    self {
      TimetableUseCase(
        userUseCase: self.userUseCase.resolve(),
        otlTimetableRepository: self.otlTimetableRepository.resolve(),
        sessionBridgeService: self.sessionBridgeService.resolve()
      )
    }.singleton
  }
}
