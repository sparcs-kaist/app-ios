//
//  MoyaProvider+Extensions.swift
//  soap
//
//  Created by Soongyu Kwon on 14/07/2025.
//

import Foundation
import Moya
import BuddyDomain
import os

private let logger = Logger(subsystem: "org.sparcs.soap", category: "Networking")

extension Response: @unchecked @retroactive Sendable {}

public enum AuthRetryConfig {
  public nonisolated(unsafe) static var tokenRefresher: (@Sendable () async throws -> Void)?
  @TaskLocal public static var isRefreshing: Bool = false
}

public extension MoyaProvider {
  func request(_ target: Target) async throws -> Response {
    do {
      return try await _request(target)
    } catch NetworkError.unauthorized {
      guard !AuthRetryConfig.isRefreshing, let refresher = AuthRetryConfig.tokenRefresher else {
        throw NetworkError.unauthorized
      }
      try await AuthRetryConfig.$isRefreshing.withValue(true) {
        try await refresher()
      }
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
            // The thrown error keeps only the status, so log what the server said about it.
            let body = String(decoding: response.data.prefix(500), as: UTF8.self)
            logger.error("\(target.method.rawValue, privacy: .public) \(target.path, privacy: .public) failed with \(response.statusCode): \(body, privacy: .public)")
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
