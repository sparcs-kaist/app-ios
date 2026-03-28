//
//  AuthEndpoint.swift
//  BuddyCore
//
//  Created by Soongyu Kwon on 28/03/2026.
//

import Alamofire
import Foundation

public enum AuthEndpoint: Endpoint {
  case requestTokens(authorizationCode: String, codeVerifier: String)
  case refreshTokens(refreshToken: String)

  private var baseURL: URL {
    BackendURL.taxiBackendURL
  }

  private var path: String {
    switch self {
    case .requestTokens:
      "/auth/sparcsapp/token/issue"
    case .refreshTokens:
      "/auth/sparcsapp/token/refresh"
    }
  }

  public var url: URL {
    baseURL.appendingPathComponent(path)
  }

  public var method: Alamofire.HTTPMethod {
    .post
  }

  public var parameters: Parameters? {
    switch self {
    case .requestTokens(_, let codeVerifier):
      [
        "codeVerifier": codeVerifier
      ]
    case .refreshTokens(let refreshToken):
      [
        "refreshToken": refreshToken
      ]
    }
  }

  public var encoding: any ParameterEncoding {
    JSONEncoding.default
  }

  public var headers: HTTPHeaders {
    switch self {
    case .requestTokens(let authorizationCode, _):
      [
        "Origin": "sparcsapp",
        "Content-Type": "application/json",
        "Cookie": "connect.sid=\(authorizationCode)"
      ]
    default:
      [
        "Origin": "sparcsapp",
        "Content-Type": "application/json",
      ]
    }
  }
}
