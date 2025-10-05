//
//  AuthTarget.swift
//  soap
//
//  Created by Soongyu Kwon on 09/07/2025.
//

import Foundation
import Moya
import BuddyDataCore

public enum AuthTarget {
  case requestTokens(authorisationCode: String, codeVerifier: String)
  case refreshTokens(refreshToken: String)
}

extension AuthTarget: TargetType {
  public var baseURL: URL {
    BackendURL.taxiBackendURL
  }

  public var path: String {
    switch self {
    case .requestTokens:
      "/auth/sparcsapp/token/issue"
    case .refreshTokens:
      "/auth/sparcsapp/token/refresh"
    }
  }

  public var method: Moya.Method {
    switch self {
    case .requestTokens, .refreshTokens:
      .post
    }
  }

  public var task: Moya.Task {
    switch self {
    case .requestTokens(_, let codeVerifier):
        .requestParameters(
          parameters: ["codeVerifier": codeVerifier],
          encoding: JSONEncoding.default
        )
    case .refreshTokens(let refreshToken):
      .requestParameters(
        parameters: ["refreshToken": "\(refreshToken)"],
        encoding: JSONEncoding.default
      )
    }
  }

  public var headers: [String: String]? {
    switch self {
    case .requestTokens(let authorisationCode, _):
      [
        "Origin": "sparcsapp",
        "Content-Type": "application/json",
        "Cookie": "connect.sid=\(authorisationCode)"
      ]
    default:
      [
        "Origin": "sparcsapp",
        "Content-Type": "application/json"
      ]
    }
  }
}
