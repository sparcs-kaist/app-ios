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
import Security
import BuddyDomain
import BuddyDataCore

public class AuthenticationService: NSObject, AuthenticationServiceProtocol, ASWebAuthenticationPresentationContextProviding {
  private let authRepository: AuthRepositoryProtocol?

  public init(authRepository: AuthRepositoryProtocol?) {
    self.authRepository = authRepository
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
    let verifierBytes = try Self.secureRandomBytes(count: 32)
    let codeVerifier = verifierBytes.base64URLEncodedString()
    let state = try Self.secureRandomBytes(count: 32).base64URLEncodedString()

    return try await withCheckedThrowingContinuation { continuation in
      guard let authURL = BackendURL.authorisationURL,
            var urlComponents = URLComponents(url: authURL, resolvingAgainstBaseURL: false) else {
        continuation.resume(throwing: AuthenticationServiceError.unknown)
        return
      }

      let codeChallenge = verifierBytes.sha256().base64URLEncodedString()
      urlComponents.queryItems = [
        URLQueryItem(name: "client", value: BackendURL.applicationName),
        URLQueryItem(name: "state", value: state),
        URLQueryItem(name: "challenge", value: codeChallenge)
      ]

      guard let authorisationURL = urlComponents.url else {
        continuation.resume(throwing: AuthenticationServiceError.unknown)
        return
      }

      let webAuthSession = ASWebAuthenticationSession(url: authorisationURL, callbackURLScheme: "sparcsapp") { callbackURL, error in
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

        guard let urlComponents = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
              let queryItems = urlComponents.queryItems,
              let session = queryItems.first(where: { $0.name == "session" })?.value,
              !session.isEmpty,
              let returnedState = queryItems.first(where: { $0.name == "state" })?.value,
              returnedState == state else {
          continuation.resume(throwing: AuthenticationServiceError.invalidCallbackURL)
          return
        }

        _Concurrency.Task {
          do {
            let tokenResponse = try await self.exchangeSessionForTokens(
              session: session,
              codeVerifier: codeVerifier
            )
            continuation.resume(returning: tokenResponse)
          } catch {
            continuation.resume(throwing: error)
          }
        }
      }

      webAuthSession.presentationContextProvider = self
      webAuthSession.additionalHeaderFields = [
        "X-Application-Name": BackendURL.applicationName
      ]
      webAuthSession.prefersEphemeralWebBrowserSession = true
      guard webAuthSession.start() else {
        continuation.resume(throwing: AuthenticationServiceError.unknown)
        return
      }
    }
  }

  private func exchangeSessionForTokens(session: String, codeVerifier: String) async throws -> SignInResponse {
    guard let authRepository else { throw AuthenticationServiceError.unknown }
    return try await authRepository.requestToken(session: session, codeVerifier: codeVerifier)
  }

  public func refreshAccessToken(refreshToken: String) async throws -> TokenResponse {
    guard let authRepository else { throw AuthenticationServiceError.unknown }
    return try await authRepository.refreshToken(refreshToken: refreshToken)
  }

  public func logout(refreshToken: String) async throws {
    guard let authRepository else { throw AuthenticationServiceError.unknown }
    try await authRepository.logout(refreshToken: refreshToken)
  }

  private static func secureRandomBytes(count: Int) throws -> Data {
    var bytes = [UInt8](repeating: 0, count: count)
    let status = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
    guard status == errSecSuccess else {
      throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
    }
    return Data(bytes)
  }
}
