//
//  AraBoardUseCaseError.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 13/02/2026.
//

import Foundation

public enum AraBoardUseCaseError: Error, LocalizedError, SourcedError, Sendable {
  public var source: ErrorSource { .useCase }
  case unknown(underlying: Error?)

  public var errorDescription: String? {
    switch self {
    case .unknown:
      return String(localized: "Unknown error occurred. Please try again.")
    }
  }
}
