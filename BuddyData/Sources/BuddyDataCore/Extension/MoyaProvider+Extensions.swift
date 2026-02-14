//
//  MoyaProvider+Extensions.swift
//  soap
//
//  Created by Soongyu Kwon on 14/07/2025.
//

import Foundation
import Moya
import BuddyDomain

extension Response: @unchecked @retroactive Sendable {}

public enum AuthRetryConfig {
  public nonisolated(unsafe) static var tokenRefresher: (@Sendable () async throws -> Void)?
}

public extension MoyaProvider {
  func request(_ target: Target) async throws -> Response {
    do {
      return try await _request(target)
    } catch NetworkError.unauthorized {
      // Attempt token refresh and retry once
      guard let refresher = AuthRetryConfig.tokenRefresher else {
        throw NetworkError.unauthorized
      }
      try await refresher()
      return try await _request(target)
    }
  }

  private func _request(_ target: Target) async throws -> Response {
    try await withCheckedThrowingContinuation { continuation in
      self.request(target) { result in
        switch result {

        case .success(let response):

          // Filtering Status Code
          guard (200...299).contains(response.statusCode) else {
            let error: NetworkError = switch response.statusCode {
            case 401: .unauthorized
            case 404: .notFound
            default: .serverError(statusCode: response.statusCode)
            }
            continuation.resume(throwing: error)
            return
          }

          continuation.resume(returning: response)

        case .failure(let moyaError):
          continuation.resume(
            throwing: NetworkErrorMapper.map(moyaError)
          )
        }
      }
    }
  }
}
