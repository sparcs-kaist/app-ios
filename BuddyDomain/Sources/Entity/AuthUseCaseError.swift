//
//  AuthUseCaseError.swift
//  soap
//
//  Created by Soongyu Kwon on 09/07/2025.
//

import Foundation

public enum AuthUseCaseError: Error, LocalizedError {
  case signInFailed(Error)
  case signOutFailed
  case refreshFailed(Error)
  case noAccessToken

  public var errorDescription: String? {
    switch self {
    case .signInFailed(let error): return String(localized: "Sign in failed: \(error.localizedDescription)", bundle: .module)
    case .signOutFailed: return String(localized: "Sign out failed.", bundle: .module)
    case .refreshFailed(let error): return String(localized: "Token refresh failed: \(error.localizedDescription)", bundle: .module)
    case .noAccessToken: return String(localized: "No access token.", bundle: .module)
    }
  }
}
