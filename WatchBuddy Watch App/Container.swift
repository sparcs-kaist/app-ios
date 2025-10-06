//
//  Container.swift
//  soap
//
//  Created by Soongyu Kwon on 06/10/2025.
//

import Foundation
import Factory
import Moya
import BuddyDomain
import BuddyDataCore
import BuddyDataWatch

extension Container {
  // MARK: - Storage
  var tokenStorage: Factory<TokenStorageProtocol> {
    self { TokenStorage() }.singleton
  }

  private var userStorage: Factory<UserStorageProtocol> {
    self { UserStorage() }.singleton
  }

  // MARK: - Services
  var tokenBridgeServiceWatch: Factory<TokenBridgeServiceWatchProtocol> {
    self {
      TokenBridgeServiceWatch(tokenStorage: self.tokenStorage.resolve())
    }.singleton
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
}
