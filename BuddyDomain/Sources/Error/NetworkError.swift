//
//  NetworkError.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 31/01/2026.
//

import Foundation

public enum NetworkError: Error, LocalizedError, SourcedError, Sendable {
  public var source: ErrorSource { .network }

  case noConnection
  case timeout
  case serverError(statusCode: Int)
  case unauthorized
  case notFound
  case unknown(underlying: Error)

  public var errorDescription: String? {
    switch self {
    case .noConnection:
      return String(localized: "No internet connection.")
    case .timeout:
      return String(localized: "Request timed out.")
    case .serverError(let code):
      return String(localized: "Server error (\(code)).")
    case .unauthorized:
      return String(localized: "Session expired. Please sign in again.")
    case .notFound:
      return String(localized: "Resources not found.")
    case .unknown:
      return String(localized: "An unexpected error occurred.")
    }
  }

  public var isRetryable: Bool {
    switch self {
    case .timeout:
      return true
    case .serverError(let code) where code >= 500:
      return true
    default:
      return false
    }
  }

  public var isRecordable: Bool {
    switch self {
    case .serverError(_), .notFound, .unknown(_):
      return true
    default:
      // No reason to record other basic network errors.
      return false
    }
  }
}
