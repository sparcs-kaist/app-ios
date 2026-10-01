//
//  AuthTarget.swift
//  soap
//
//  Created by Soongyu Kwon on 09/07/2025.
//

import Foundation
import Moya

public enum AuthTarget {
  case requestTokens(session: String, codeVerifier: String)
  case refreshTokens(refreshToken: String)
  case logout(refreshToken: String)
}

extension AuthTarget: TargetType {
  public var baseURL: URL {
    BackendURL.feedBackendURL
  }

  public var path: String {
    switch self {
    case .requestTokens:
      "/auth/token/issue"
    case .refreshTokens:
      "/auth/token/refresh"
    case .logout:
      "/auth/logout"
    }
  }

  public var method: Moya.Method {
    switch self {
    case .requestTokens, .refreshTokens, .logout:
      .post
    }
  }

  public var task: Moya.Task {
    switch self {
    case .requestTokens(let session, let codeVerifier):
        .requestParameters(
          parameters: ["session": session, "codeVerifier": codeVerifier],
          encoding: JSONEncoding.default
        )
    case .refreshTokens(let refreshToken):
      .requestParameters(
        parameters: ["refreshToken": "\(refreshToken)"],
        encoding: JSONEncoding.default
      )
    case .logout(let refreshToken):
      .requestParameters(
        parameters: ["refreshToken": refreshToken],
        encoding: JSONEncoding.default
      )
    }
  }

  public var headers: [String: String]? {
    [
      "Origin": "sparcsapp",
      "Content-Type": "application/json"
    ]
  }
}
