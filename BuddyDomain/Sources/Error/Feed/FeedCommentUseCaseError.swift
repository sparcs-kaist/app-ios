//
//  FeedCommentUseCaseError.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 05/02/2026.
//

import Foundation

public enum FeedCommentUseCaseError: Error, LocalizedError, SourcedError, Sendable {
  public var source: ErrorSource { .useCase }
  case cannotDeleteCommentWithVote
  case unknown(underlying: Error?)

  public var errorDescription: String? {
    switch self {
    case .cannotDeleteCommentWithVote:
      return String(localized: "Cannot delete comment that has votes.")
    case .unknown:
      return String(localized: "Unknown error occurred. Please try again.")
    }
  }
}
