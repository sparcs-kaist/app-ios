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

  // MARK: - Services
  private var taxiChatService: Factory<TaxiChatServiceProtocol> {
    self {
      TaxiChatService(tokenStorage: self.tokenStorage.resolve())
    }.singleton
  }

  // MARK: - Use Cases

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
}
