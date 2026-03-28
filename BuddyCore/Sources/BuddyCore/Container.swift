//
//  Container.swift
//  BuddyCore
//
//  Created by Soongyu Kwon on 28/03/2026.
//

import Factory
import Foundation
import BuddyCoreAuth
import BuddyCoreNetworking
import BuddyDomain
import Alamofire

extension Container: @retroactive AutoRegistering {
  private var authConfiguration: Factory<AuthConfiguration> {
    self {
      AuthConfiguration(
        baseURL: BackendURL.taxiBackendURL,
        oauthStartURL: BackendURL.authorisationURL,
        callbackScheme: "sparcsapp",
        callbackHost: "authorize",
        refreshThreshold: 60
      )
    }
  }

  private var sessionStore: Factory<SessionStore> {
    self { SessionStore() }.singleton
  }

  private var tokenStore: Factory<TokenStoring> {
    self { KeychainTokenStore() }.singleton
  }

  private var webAuthenticator: Factory<WebAuthenticating> {
    self { @MainActor in
      WebAuthenticator(configuration: self.authConfiguration.resolve())
    }
  }

  private var alamofireSession: Factory<Session> {
    self { Session() }.singleton
  }

  public func autoRegister() {
    authService.register {
      AuthService(
        configuration: self.authConfiguration.resolve(),
        sessionStore: self.sessionStore.resolve(),
        tokenStore: self.tokenStore.resolve(),
        webAuthenticator: self.webAuthenticator.resolve(),
        session: self.alamofireSession.resolve()
      )
    }
    .scope(.singleton)
  }
}
