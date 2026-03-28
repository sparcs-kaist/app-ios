//
//  AuthService.swift
//  BuddyCore
//
//  Created by Soongyu Kwon on 28/03/2026.
//

import Alamofire
import Foundation
import BuddyDomain
import BuddyCoreNetworking

public final class AuthService: AuthServicing, Sendable {
  private let configuration: AuthConfiguration
  private let sessionStore: SessionStore
  private let tokenStore: TokenStoring
  private let webAuthenticator: WebAuthenticating
  private let session: Session

  private let refreshCoordinator = RefreshCoordinator()

  public init(
    configuration: AuthConfiguration,
    sessionStore: SessionStore,
    tokenStore: TokenStoring,
    webAuthenticator: WebAuthenticating,
    session: Session
  ) {
    self.configuration = configuration
    self.sessionStore = sessionStore
    self.tokenStore = tokenStore
    self.webAuthenticator = webAuthenticator
    self.session = session
  }

  public func bootstrap() async -> Bool {
    do {
      guard let tokenPair = try tokenStore.load() else {
        return false
      }

      await sessionStore.update(tokenPair)
      return true
    } catch {
      return false
    }
  }

  public func login() async throws {
    let callbackURL = try await webAuthenticator.authenticate()
    let code = try extractAuthorizationCode(from: callbackURL)
    print(callbackURL)
    print(code)
  }

  public func validAccessToken() async throws -> String {
    guard let tokenPair = await sessionStore.currentTokenPair() else {
      throw AuthServiceError.unauthorized
    }

//    if tokenPair.expiry.timeIntervalSinceNow < configuration.refreshThreshold {
//      let refreshed = try await refreshToken()
//      return refreshed.accessToken
//    }

    return tokenPair.accessToken
  }

  public func logout() async {
    try? tokenStore.clear()
    await sessionStore.clear()
  }

//  private func refreshToken() async throws -> TokenPair {
//    try await refreshCoordinator.refreshIfNeeded {
//      guard let refreshToken = await self.sessionStore.currentRefreshToken() else {
//        throw NetworkError.unauthorized
//      }
//
//      let endpoint = AuthEndpoint.refreshTokens(refreshToken: refreshToken)
//
//
//    }
//  }

  private func exchangeCodeForToken(code: String) async throws -> TokenPair {
    let endpoint = AuthEndpoint.requestTokens(
      authorizationCode: code,
      codeVerifier: Data(configuration.codeVerifier.utf8).base64URLEncodedString()
    )

  }

  private func extractAuthorizationCode( from callbackURL: URL) throws -> String {
    guard
      callbackURL.scheme == configuration.callbackScheme,
      callbackURL.host == configuration.callbackHost,
      let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
      let queryItems = components.queryItems,
      let authorizationCode = queryItems.first(where: { $0.name == "session" })?.value
    else {
      throw AuthServiceError.invalidCallbackURL
    }

    return authorizationCode
  }
}

public enum AuthServiceError: Error, LocalizedError {
  case unauthorized
  case invalidCallbackURL

  public var errorDescription: String? {
    switch self {
    case .unauthorized:
      return "Your session has expired."
    case .invalidCallbackURL:
      return "The callback URL is invalid."
    }
  }
}
