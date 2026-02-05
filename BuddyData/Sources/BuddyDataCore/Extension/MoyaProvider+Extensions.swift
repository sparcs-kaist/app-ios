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

public extension MoyaProvider {
  func request(_ target: Target) async throws -> Response {
    try await withCheckedThrowingContinuation { continuation in
      self.request(target) { result in
        switch result {

        case .success(let response):

          // Filtering Status Code
          guard (200...299).contains(response.statusCode) else {
            continuation.resume(
              throwing: NetworkError.serverError(statusCode: response.statusCode)
            )
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
