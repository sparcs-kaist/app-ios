//
//  NetworkErrorMapper.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 31/01/2026.
//

import Foundation
import Moya
import Alamofire
import BuddyDomain

public enum NetworkErrorMapper {
  // Maps MoyaError to domain NetworkError
  public static func map(_ error: Error) -> NetworkError {
    guard let moyaError = error as? MoyaError else {
      return .unknown(underlying: error)
    }

    // Check for underlying network issues (no connection, timeout)
    if let afError = extractAFError(from: moyaError) {
      if let urlError = afError.underlyingError as? URLError {
        switch urlError.code {
        case .notConnectedToInternet, .dataNotAllowed, .networkConnectionLost:
          return .noConnection
        case .timedOut:
          return .timeout
        default:
          break
        }
      }
    }

    if let response = moyaError.response {
      switch response.statusCode {
      case 401:
        return .unauthorized
      case 404:
        return .notFound
      default:
        return .serverError(statusCode: response.statusCode)
      }
    }

    return .unknown(underlying: error)
  }

  private static func extractAFError(from moyaError: MoyaError) -> AFError? {
    if case let .underlying(afError, _) = moyaError {
      return afError as? AFError
    }
    return nil
  }
}
