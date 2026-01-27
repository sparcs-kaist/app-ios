//
//  Container.swift
//  BuddyDataiOS
//
//  Created by Soongyu Kwon on 27/01/2026.
//

import Foundation
import Factory
import BuddyDomain
import BuddyDataCore
import Moya

extension Container: @retroactive AutoRegistering {
  private var tokenStorage: Factory<TokenStorageProtocol> {
    self { TokenStorage() }.singleton
  }

  private var userStorage: Factory<UserStorageProtocol> {
    self { UserStorage() }.singleton
  }

  private var authPlugin: Factory<AccessTokenPlugin> {
    self {
      let tokenStorage = self.tokenStorage.resolve()
      return AccessTokenPlugin { _ in
        return tokenStorage.getAccessToken() ?? ""
      }
    }
  }

  public func autoRegister() {

    // MARK: Taxi
    taxiRoomRepository.register {
      TaxiRoomRepository(provider: MoyaProvider<TaxiRoomTarget>(plugins: [
        self.authPlugin.resolve()
      ]))
    }

    taxiUserRepository.register {
      TaxiUserRepository(provider: MoyaProvider<TaxiUserTarget>(plugins: [
        self.authPlugin.resolve()
      ]))
    }

    taxiChatRepository.register {
      TaxiChatRepository(
        provider: MoyaProvider<TaxiChatTarget>(plugins: [self.authPlugin.resolve()])
      )
    }

    taxiReportRepository.register {
      TaxiReportRepository(
        provider: MoyaProvider<TaxiReportTarget>(plugins: [self.authPlugin.resolve()])
      )
    }
  }
}
