//
//  AddFriendError.swift
//  BuddyDomain
//

import Foundation

/// Why the server refused a friend code: each a different thing for the user to do.
public enum AddFriendError: Error, LocalizedError, SourcedError, Sendable, Equatable {
  public var source: ErrorSource { .repository }

  /// No one has this code.
  case invalidCode
  /// The code is the user's own.
  case ownCode
  /// Too many codes tried; `retryAfter` is how long to wait, when the server says.
  case tooManyAttempts(retryAfter: TimeInterval?)
  /// Codes can't be checked right now.
  case unavailable

  public var errorDescription: String? {
    switch self {
    case .invalidCode:
      String(localized: "No one has this code. Check it with your friend.", bundle: .module)
    case .ownCode:
      String(localized: "This is your own code. Enter your friend’s code instead.", bundle: .module)
    case .tooManyAttempts(let retryAfter):
      if let wait = Self.formattedWait(retryAfter) {
        String(localized: "Too many attempts. Try again in \(wait).", bundle: .module)
      } else {
        String(localized: "Too many attempts. Try again later.", bundle: .module)
      }
    case .unavailable:
      String(localized: "Adding friends by code isn’t available right now. Try again later.", bundle: .module)
    }
  }

  /// "2 minutes" or "1 hour, 5 minutes", rounded up to the minute.
  private static func formattedWait(_ seconds: TimeInterval?) -> String? {
    guard let seconds, seconds > 0 else { return nil }
    let minutes = Int((seconds / 60).rounded(.up))
    return Duration.seconds(minutes * 60).formatted(.units(allowed: [.hours, .minutes], width: .wide))
  }
}
