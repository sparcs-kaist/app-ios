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
    _isAuthenticatedSubject.value = tokenStorage.getAccessToken() != nil && !tokenStorage.isTokenExpired()
  }

  func getAccessToken() -> String? {
    if tokenStorage.isTokenExpired() {
      logger.warning("[AuthUseCase] Access token is expired. Attempting to refresh...")

      Task {
        do {
          try await refreshAccessTokenIfNeeded()
        } catch {
          logger.error("[AuthUseCase] Failed to refresh expired token: \(error.localizedDescription)")
        }
      }
      
      return nil
    }
    
    return tokenStorage.getAccessToken()
  }
  
  func getValidAccessToken() async throws -> String? {
    if tokenStorage.isTokenExpired() {
      logger.info("[AuthUseCase] Access token is expired. Refreshing...")
      try await refreshAccessTokenIfNeeded()
    }
    
    return tokenStorage.getAccessToken()
  }

  func refreshAccessTokenIfNeeded() async throws {
    if let accessToken = tokenStorage.getAccessToken(), !tokenStorage.isTokenExpired() {
      logger.info("[AuthUseCase] Access token is still valid. No refresh needed.")
      return
    }

    guard let currentRefreshToken = tokenStorage.getRefreshToken() else {
      // No refresh token found, sign out.
      _isAuthenticatedSubject.value = false
      throw AuthUseCaseError.refreshFailed(NSError(domain: "AuthUseCase", code: 401, userInfo: [NSLocalizedDescriptionKey: "No refresh token available"]))
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
