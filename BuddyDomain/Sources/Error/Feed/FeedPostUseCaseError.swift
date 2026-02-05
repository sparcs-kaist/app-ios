//
//  FeedPostUseCaseError.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 04/02/2026.
//

import Foundation

public enum FeedPostUseCaseError: Error, LocalizedError, SourcedError, Sendable {
  public var source: ErrorSource { .useCase }
  case cannotDeletePostWithVoteOrComment
  case unknown(underlying: Error?)

  public var errorDescription: String? {
    switch self {
    case .cannotDeletePostWithVoteOrComment:
      return String(localized: "Cannot delete post that has votes or comments.")
    case .unknown:
      return String(localized: "Unknown error occurred. Please try again.")
    }
  }
}
