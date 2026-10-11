//
//  SummarisationError.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 12/10/2026.
//

import Foundation

/// Why a piece of text could not be summarised. Only `failed` is worth retrying
/// unchanged.
public enum SummarisationError: LocalizedError, Equatable, Sendable {
  /// The device doesn't support Apple Intelligence, it is switched off, or the
  /// model is still downloading.
  case unavailable
  /// The text tripped the model's safety guardrails.
  case unsafeContent
  case failed

  public var errorDescription: String? {
    switch self {
    case .unavailable:
      String(localized: "Apple Intelligence isn't available right now. Check that it's turned on in Settings, then try again.", bundle: .module)
    case .unsafeContent:
      String(localized: "This can't be summarised.", bundle: .module)
    case .failed:
      String(localized: "Couldn't summarise this. Please try again.", bundle: .module)
    }
  }
}
