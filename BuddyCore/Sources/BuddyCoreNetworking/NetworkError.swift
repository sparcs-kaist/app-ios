//
//  NetworkError.swift
//  BuddyCore
//
//  Created by Soongyu Kwon on 28/03/2026.
//

import Foundation

public enum NetworkError: Error, LocalizedError {
  case unauthorized
  case network
  case server(statusCode: Int)
  case invalidResponse
  case decoding
  case invalidCallbackURL
  case missingAuthorizationCode
  case unknown

  public var errorDescription: String? {
    switch self {
    case .unauthorized:
      return "Your session has expired."
    case .network:
      return "Network connection failed."
    case .server(let statusCode):
      return "Server error (\(statusCode))."
    case .invalidResponse:
      return "Invalid response."
    case .decoding:
      return "Failed to decode server response."
    case .invalidCallbackURL:
      return "Invalid login callback."
    case .missingAuthorizationCode:
      return "Missing authorization code."
    case .unknown:
      return "Something went wrong."
    }
  }
}
