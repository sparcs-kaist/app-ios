//
//  FeedImageUseCaseError.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 05/02/2026.
//

import Foundation

public enum FeedImageUseCaseError: Error, LocalizedError, SourcedError, Sendable {
  public var source: ErrorSource { .useCase }
  case imageCompressionFailed
  case unknown(underlying: Error?)

  public var errorDescription: String? {
    switch self {
    case .imageCompressionFailed:
      return String(localized: "Failed to compress image for upload.")
    case .unknown:
      return String(localized: "Unknown error occurred. Please try again.")
    }
  }
}
