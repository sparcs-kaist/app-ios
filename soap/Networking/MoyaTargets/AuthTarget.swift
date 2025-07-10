//
//  AuthTarget.swift
//  soap
//
//  Created by Soongyu Kwon on 09/07/2025.
//

import Foundation
import Moya

enum AuthTarget {
  case requestTokens(authorisationCode: String, codeVerifier: String)
  case refreshTokens(refreshToken: String)
}

extension AuthTarget: TargetType {
  var baseURL: URL {
    Constants.taxiBackendURL
  }

  var path: String {
    switch self {
    case .requestTokens:
      "/auth/sparcsapp/token/issue"
    case .refreshTokens:
      "/auth/sparcsapp/token/refresh"
    }
  }

  var method: Moya.Method {
    switch self {
    case .requestTokens, .refreshTokens:
      .post
    }
  }

  var task: Moya.Task {
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

  var headers: [String : String]? {
    switch self {
    case .requestTokens(let authorisationCode, _):
      [
        "Origin": "taxi.sparcs.org",
        "Content-Type": "application/json",
        "Cookie": "connect.sid=\(authorisationCode)"
      ]
    default:
      [
        "Origin": "taxi.sparcs.org",
        "Content-Type": "application/json"
      ]
    }
  }
}
