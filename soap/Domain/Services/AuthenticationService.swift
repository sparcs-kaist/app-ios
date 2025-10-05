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

class AuthenticationService: NSObject, AuthenticationServiceProtocol, ASWebAuthenticationPresentationContextProviding {
  private let provider: MoyaProvider<AuthTarget>
  private let codeVerifier: String

  init(provider: MoyaProvider<AuthTarget>) {
    self.provider = provider
    
    self.codeVerifier = UUID().uuidString.replacingOccurrences(of: "-", with: "")
  }
  
  func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
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
  
  func authenticate() async throws -> SignInResponse {
    return try await withCheckedThrowingContinuation { continuation in
      guard let authURL = Constants.authorisationURL,
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

  func exchangeCodeForTokens(_ authorisationCode: String) async throws -> SignInResponse {
    return try await withCheckedThrowingContinuation { continuation in
      provider
        .request(
          .requestTokens(
            authorisationCode: authorisationCode,
            codeVerifier: Data(codeVerifier.utf8).base64URLEncodedString()
          )
        ) { result in
          switch result {
          case .success(let response):
            do {
              let tokenResponse = try response.map(SignInResponseDTO.self).toModel()
              continuation.resume(returning: tokenResponse)
            } catch {
              continuation.resume(throwing: error)
            }
          case .failure(let error):
            continuation.resume(throwing: AuthenticationServiceError.tokenExchangeFailed(error))
          }
        }
    }
  }

  func refreshAccessToken(refreshToken: String) async throws -> TokenResponse {
    return try await withCheckedThrowingContinuation { continuation in
      provider.request(.refreshTokens(refreshToken: refreshToken)) { result in
        switch result {
        case .success(let response):
          do {
            let tokenResponse = try response.map(TokenResponseDTO.self).toModel()
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
