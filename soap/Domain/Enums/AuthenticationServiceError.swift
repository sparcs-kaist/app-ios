//
//  AuthenticationServiceError.swift
//  soap
//
//  Created by Soongyu Kwon on 09/07/2025.
//

import Foundation

enum AuthenticationServiceError: Error, LocalizedError {
  case userCancelled
  case invalidCallbackURL
  case tokenExchangeFailed(Error)
  case tokenRefreshFailed(Error)
  case noRefreshTokenAvailable
  case unknown

  var errorDescription: String? {
    switch self {
    case .userCancelled: return String(localized: "Authentication was cancelled by the user.")
    case .invalidCallbackURL: return String(localized: "Invalid callback URL received.")
    case .tokenExchangeFailed(let error): return String(localized: "Failed to exchange code for tokens: \(error.localizedDescription)")
    case .tokenRefreshFailed(let error): return String(localized: "Failed to refresh access token: \(error.localizedDescription)")
    case .noRefreshTokenAvailable: return String(localized: "No refresh token available.")
    case .unknown: return String(localized: "An unknown authentication error occurred.")
    }
  }
}
