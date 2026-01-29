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
import BuddyDomain
import BuddyDataCore

public class AuthenticationService: NSObject, AuthenticationServiceProtocol, ASWebAuthenticationPresentationContextProviding {
  private let authRepository: AuthRepositoryProtocol?
  private let codeVerifier: String

  public init(authRepository: AuthRepositoryProtocol?) {
    self.authRepository = authRepository
    self.codeVerifier = UUID().uuidString.replacingOccurrences(of: "-", with: "")
  }
  
  public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    if let windowScene = UIApplication.shared.connectedScenes
      .compactMap({ $0 as? UIWindowScene })
      .first(where: { $0.activationState == .foregroundActive }) {
      return ASPresentationAnchor(windowScene: windowScene)
    } else {
      // Fallback: Return a default anchor or handle gracefully
      assertionFailure("No valid UIWindowScene found for authentication presentation.")
      return ASPresentationAnchor()
    }
  }
  
  public func authenticate() async throws -> SignInResponse {
    return try await withCheckedThrowingContinuation { continuation in
      guard let authURL = BackendURL.authorisationURL,
            var urlComponents = URLComponents(url: authURL, resolvingAgainstBaseURL: false) else {
        continuation.resume(throwing: AuthenticationServiceError.unknown)
        return
      }

      let codeChallenge = Data(codeVerifier.utf8).sha256().base64URLEncodedString()
      urlComponents.queryItems = [
        URLQueryItem(name: "codeChallenge", value: codeChallenge)
      ]

      guard let authorisationURL = urlComponents.url else {
        continuation.resume(throwing: AuthenticationServiceError.unknown)
        return
      }

      let session = ASWebAuthenticationSession(url: authorisationURL, callbackURLScheme: "sparcsapp") { callbackURL, error in
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
              let authorisationCode = queryItems.first(where: { $0.name == "session" })?.value else{
          continuation.resume(throwing: AuthenticationServiceError.invalidCallbackURL)
          return
        }

        _Concurrency.Task {
          do {
            let tokenResponse = try await self.exchangeCodeForTokens(authorisationCode)
            continuation.resume(returning: tokenResponse)
          } catch {
            continuation.resume(throwing: error)
          }
        }
      }

      session.presentationContextProvider = self
      session.prefersEphemeralWebBrowserSession = true
      session.start()
    }
  }

  public func exchangeCodeForTokens(_ authorisationCode: String) async throws -> SignInResponse {
    guard let authRepository else { throw AuthenticationServiceError.unknown }
    return try await authRepository
      .requestToken(authorisationCode: authorisationCode, codeVerifier: Data(self.codeVerifier.utf8).base64URLEncodedString())
  }

  public func refreshAccessToken(refreshToken: String) async throws -> TokenResponse {
    guard let authRepository else { throw AuthenticationServiceError.unknown }
    return try await authRepository.refreshToken(refreshToken: refreshToken)
  }
}
