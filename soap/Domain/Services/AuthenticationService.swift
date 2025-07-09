//
//  AuthenticationService.swift
//  soap
//
//  Created by Soongyu Kwon on 09/07/2025.
//

import Foundation
import Moya
import AuthenticationServices
import UIKit

class AuthenticationService: NSObject, AuthenticationServiceProtocol, ASWebAuthenticationPresentationContextProviding {
  private let provider: MoyaProvider<AuthTarget>

  init(provider: MoyaProvider<AuthTarget>) {
    self.provider = provider
  }

  func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    if let windowScene = UIApplication.shared.connectedScenes
        .compactMap({ $0 as? UIWindowScene })
        .first(where: { $0.activationState == .foregroundActive }) {
        return ASPresentationAnchor(windowScene: windowScene)
    } else {
        // Fallback: Return a default anchor or handle gracefully
        assertionFailure("No valid UIWindowScene found for authentication presentation.")
        return ASPresentationAnchor() // This line may still be deprecated, but is guarded
    }
  }

  func authenticate() async throws -> TokenResponseDTO {
    return try await withCheckedThrowingContinuation { continuation in
      guard let authURL = Constants.authorizationURL else {
        continuation.resume(throwing: AuthenticationServiceError.unknown)
        return
      }

      let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: "sparcsapp") { callbackURL, error in
        if let error = error {
          // Handle user cancellation or other session errors
          if let authError = error as? ASWebAuthenticationSessionError,
             authError.code == ASWebAuthenticationSessionError.canceledLogin {
            continuation.resume(throwing: AuthenticationServiceError.userCancelled)
          } else {
            continuation.resume(throwing: error)
          }
          return
        }

        guard let callbackURL = callbackURL else {
          continuation.resume(throwing: AuthenticationServiceError.invalidCallbackURL)
          return
        }

        // Extract the access token and refresh token
        guard let urlComponents = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
              let queryItems = urlComponents.queryItems,
              let accessToken = queryItems.first(where: { $0.name == "accesstoken" })?.value,
              let refreshToken = queryItems.first(where: { $0.name == "refreshtoken" })?.value else{
          continuation.resume(throwing: AuthenticationServiceError.invalidCallbackURL)
          return
        }

        let tokenResponse = TokenResponseDTO(
          accessToken: accessToken,
          refreshToken: refreshToken
        )
        continuation.resume(returning: tokenResponse)
      }

      session.presentationContextProvider = self
      session.prefersEphemeralWebBrowserSession = true
      session.start()
    }
  }

  func refreshAccessToken(refreshToken: String) async throws -> TokenResponseDTO {
    return try await withCheckedThrowingContinuation { continuation in
      provider.request(.refreshTokens(refreshToken: refreshToken)) { result in
        switch result {
        case .success(let response):
          do {
            let tokenResponse = try response.map(TokenResponseDTO.self)
            continuation.resume(returning: tokenResponse)
          } catch {
            continuation.resume(throwing: error)
          }
        case .failure(let error):
          continuation.resume(throwing: AuthenticationServiceError.tokenRefreshFailed(error))
        }
      }
    }
  }
}

