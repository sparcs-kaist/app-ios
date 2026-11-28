//
//  AuthUseCaseError.swift
//  soap
//
//  Created by Soongyu Kwon on 09/07/2025.
//

import Foundation

/// The service sign-in was talking to when it failed, so the error can name it.
public enum SignInStep: Sendable, Equatable {
  case sso
  case ara
  case otl
  case taxi

  /// Service names are product names and are not translated.
  var serviceName: String {
    switch self {
    case .sso: "SPARCS SSO"
    case .ara: "Ara"
    case .otl: "OTL"
    case .taxi: "Taxi"
    }
  }
}

public enum AuthUseCaseError: Error, LocalizedError {
  case signInFailed(step: SignInStep, Error)
  case signOutFailed
  case refreshFailed(Error)
  case noAccessToken

  /// True when the user dismissed the SSO sheet themselves, which is not worth reporting.
  public var isUserCancellation: Bool {
    if case .signInFailed(.sso, AuthenticationServiceError.userCancelled) = self { return true }
    return false
  }

  public var errorDescription: String? {
    switch self {
    case .signInFailed(let step, let error):
      let summary = String(localized: "Failed to sign in to \(step.serviceName). Please try again later.", bundle: .module)
      return "\(summary)\n\n\(error.localizedDescription)"
    case .signOutFailed: return String(localized: "Sign out failed.", bundle: .module)
    case .refreshFailed(let error): return String(localized: "Token refresh failed: \(error.localizedDescription)", bundle: .module)
    case .noAccessToken: return String(localized: "No access token.", bundle: .module)
    }
  }
}
