//
//  ReviewUseCaseError.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 13/03/2026.
//

import Foundation

public enum ReviewUseCaseError: Error, LocalizedError, SourcedError, Sendable {
  public var source: ErrorSource { .useCase }
  case unknown(underlying: Error?)

  public var errorDescription: String? {
    switch self {
    case .unknown:
      return String(localized: "Unknown error occurred. Please try again.")
    }
  }
}
