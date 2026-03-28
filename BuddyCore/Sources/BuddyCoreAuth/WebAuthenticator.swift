//
//  WebAuthenticator.swift
//  BuddyCore
//
//  Created by Soongyu Kwon on 28/03/2026.
//

import AuthenticationServices
import Foundation
import UIKit
import BuddyDomain
import CryptoKit

@MainActor
public final class WebAuthenticator: NSObject, WebAuthenticating {
  private let configuration: AuthConfiguration
  private var currentSession: ASWebAuthenticationSession?

  public init(configuration: AuthConfiguration) {
    self.configuration = configuration
  }

  public func authenticate() async throws -> URL {
    try await withCheckedThrowingContinuation { continuation in
      guard var urlComponents = URLComponents(
        url: configuration.oauthStartURL,
        resolvingAgainstBaseURL: false
      ) else {
        continuation.resume(throwing: WebAuthenticatorError.failedToStart)
        return
      }

      let codeChallenge = Data(configuration.codeVerifier.utf8).sha256().base64URLEncodedString()
      urlComponents.queryItems = [
        URLQueryItem(name: "codeChallenge", value: codeChallenge)
      ]

      guard let authorizationURL = urlComponents.url else {
        continuation.resume(throwing: WebAuthenticatorError.failedToStart)
        return
      }

      let session = ASWebAuthenticationSession(
        url: authorizationURL,
        callbackURLScheme: configuration.callbackScheme
      ) { callbackURL, error in
        self.currentSession = nil

        if let error {
          continuation.resume(throwing: error)
          return
        }

        guard let callbackURL else {
          continuation.resume(throwing: WebAuthenticatorError.noCallbackURL)
          return
        }

        continuation.resume(returning: callbackURL)
      }

      session.prefersEphemeralWebBrowserSession = false
      session.presentationContextProvider = ASWebAuthenticationPresentationAnchorProvider.shared
      self.currentSession = session

      if !session.start() {
        self.currentSession = nil
        continuation.resume(throwing: WebAuthenticatorError.failedToStart)
      }
    }
  }
}

enum WebAuthenticatorError: Error, LocalizedError {
  case noCallbackURL
  case failedToStart

  var errorDescription: String? {
    switch self {
    case .noCallbackURL:
      return "No callback URL"
    case .failedToStart:
      return "Failed to start web authentication session"
    }
  }
}

extension Data {
  func sha256() -> Data {
    let hash = SHA256.hash(data: self)
    return Data(hash)
  }

  func base64URLEncodedString() -> String {
    return self.base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
  }
}


final class ASWebAuthenticationPresentationAnchorProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
  static let shared = ASWebAuthenticationPresentationAnchorProvider()

  func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    let windowScenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    if let keyWindow = windowScenes.compactMap(\.keyWindow).first {
      return keyWindow
    }
    // Fall back to the first available window, or create one attached to the first scene.
    if let scene = windowScenes.first {
      return scene.windows.first ?? UIWindow(windowScene: scene)
    }
    fatalError("No connected window scenes available")
  }
}
