//
//  AuthUseCase.swift
//  soap
//
//  Created by Soongyu Kwon on 09/07/2025.
//

import Foundation
import Combine
import Observation

@Observable
class AuthUseCase: AuthUseCaseProtocol {
  private let authenticationService: AuthenticationServiceProtocol
  private let tokenStorage: TokenStorageProtocol

  private let _isAuthenticatedSubject = CurrentValueSubject<Bool, Never>(false)
  var isAuthenticatedPublisher: AnyPublisher<Bool, Never> {
    _isAuthenticatedSubject.eraseToAnyPublisher()
  }

  init(authenticationService: AuthenticationServiceProtocol, tokenStorage: TokenStorageProtocol) {
    self.authenticationService = authenticationService
    self.tokenStorage = tokenStorage
    _isAuthenticatedSubject.value = tokenStorage.getAccessToken() != nil
  }

  func getAccessToken() -> String? {
    return tokenStorage.getAccessToken()
  }

  func refreshAccessTokenIfNeeded() async throws {
    if tokenStorage.getAccessToken() != nil {
      // Access token already in memory. No refresh needed at this point
      return
    }

    guard let currentRefreshToken = tokenStorage.getRefreshToken() else {
      // No refresh token found, sign out.
      _isAuthenticatedSubject.value = false
      return
    }

    // Attempts to refresh token using refresh token from Keychain
    do {
      let tokenResponse = try await authenticationService.refreshAccessToken(
        refreshToken: currentRefreshToken
      )
      tokenStorage
        .save(accessToken: tokenResponse.accessToken, refreshToken: tokenResponse.refreshToken)
      _isAuthenticatedSubject.value = true
      logger.info("[AuthUseCase] Successfully refreshed access token.")
    } catch {
      logger.error("[AuthUseCase] Token refresh failed. \(error.localizedDescription)")
      // TODO: DO NOT CLEAR TOKENS IF IT'S NETWORK UNAVAILABLE ERROR
      tokenStorage.clearTokens()
      _isAuthenticatedSubject.value = false
      throw AuthUseCaseError.refreshFailed(error)
    }
  }

  func signIn() async throws {
    do {
      let tokenResponse = try await authenticationService.authenticate()
      tokenStorage
        .save(accessToken: tokenResponse.accessToken, refreshToken: tokenResponse.refreshToken)
      _isAuthenticatedSubject.value = true
      logger.info("[AuthUseCase] Signed In")
    } catch {
      _isAuthenticatedSubject.value = false
      logger.error(error)
      throw AuthUseCaseError.signInFailed(error)
    }
  }

  func signOut() async throws {
    tokenStorage.clearTokens()
    _isAuthenticatedSubject.value = false
    logger.info("[AuthUseCase] Signed Out")
  }
}
