//
//  AuthUseCaseError.swift
//  soap
//
//  Created by Soongyu Kwon on 09/07/2025.
//

import Foundation

enum AuthUseCaseError: Error, LocalizedError {
  case signInFailed(Error)
  case signOutFailed
  case refreshFailed(Error)
  case noAccessToken

  var errorDescription: String? {
    switch self {
    case .signInFailed(let error): return "Sign in failed: \(error.localizedDescription)"
    case .signOutFailed: return "Sign out failed."
    case .refreshFailed(let error): return "Token refresh failed: \(error.localizedDescription)"
    case .noAccessToken: return "No access token."
    }
  }
}
