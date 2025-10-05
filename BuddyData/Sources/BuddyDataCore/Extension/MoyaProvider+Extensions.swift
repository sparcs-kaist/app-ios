//
//  MoyaProvider+Extensions.swift
//  soap
//
//  Created by Soongyu Kwon on 14/07/2025.
//

import Foundation
import Moya

extension Response: @unchecked @retroactive Sendable {}

public extension MoyaProvider {
  func request(_ target: Target) async throws -> Response {
    return try await withCheckedThrowingContinuation { continuation in
      self.request(target) { result in
        switch result {
        case .success(let response):
          continuation.resume(returning: response)
        case .failure(let error):
          continuation.resume(throwing: error)
        }
      }
    }
  }
}
