//
//  AlamofireAPIClient.swift
//  BuddyCore
//
//  Created by Soongyu Kwon on 28/03/2026.
//

import Alamofire
import Foundation
import BuddyDomain

struct AlamofireAPIClient: APIClient {
  let session: Session
  let authService: AuthServicing

  func request<T: Decodable & Sendable>(
    _ endpoint: Endpoint,
    as type: T.Type
  ) async throws -> T {
    do {
      return try await send(endpoint, as: type)
    } catch NetworkError.unauthorized {
      _ = try await authService.validAccessToken()
      return try await send(endpoint, as: type)
    }
  }

  private func performUnauthenticatedRequest<T: Decodable & Sendable>(
    _ endpoint: Endpoint,
    as type: T.Type
  ) async throws -> T {
    let response = await session.request(
      endpoint.url,
      method: endpoint.method,
      parameters: endpoint.parameters,
      encoding: endpoint.encoding,
      headers: endpoint.headers
    )
    .serializingDecodable(T.self)
    .response

    if let statusCode = response.response?.statusCode {
      switch statusCode {
      case 200..<300:
        break
      case 401:
        throw NetworkError.unauthorized
      default:
        throw NetworkError.server(statusCode: statusCode)
      }
    }

    switch response.result {
    case .success(let value):
      return value
    case .failure(let error):
      if error.isResponseSerializationError {
        throw NetworkError.decoding
      } else {
        throw NetworkError.network
      }
    }
  }

  private func send<T: Decodable & Sendable>(
    _ endpoint: Endpoint,
    as type: T.Type
  ) async throws -> T {
    let token = try await authService.validAccessToken()

    var headers = endpoint.headers
    headers.add(.authorization(bearerToken: token))

    let response = await session.request(
      endpoint.url,
      method: endpoint.method,
      parameters: endpoint.parameters,
      encoding: endpoint.encoding,
      headers: headers
    )
    .serializingDecodable(T.self)
    .response

    if let statusCode = response.response?.statusCode {
      switch statusCode {
      case 200..<300:
        break
      case 401:
        throw NetworkError.unauthorized
      default:
        throw NetworkError.server(statusCode: statusCode)
      }
    }

    switch response.result {
    case .success(let value):
      return value
    case .failure(let error):
      if error.isResponseSerializationError {
        throw NetworkError.decoding
      } else {
        throw NetworkError.network
      }
    }
  }
}
