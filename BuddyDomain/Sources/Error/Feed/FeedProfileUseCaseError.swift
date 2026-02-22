//
//  FeedProfileUseCaseError.swift
//  BuddyDomain
//
//  Created by 하정우 on 2/22/26.
//

import Foundation

public enum FeedProfileUseCaseError: Error, LocalizedError, SourcedError, Sendable {
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
