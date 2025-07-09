//
//  AuthTarget.swift
//  soap
//
//  Created by Soongyu Kwon on 09/07/2025.
//

import Foundation
import Moya

enum AuthTarget {
  case refreshTokens(refreshToken: String)
}

extension AuthTarget: TargetType {
  var baseURL: URL {
    switch self {
    case .refreshTokens:
      return Constants.taxiBackendURL
    }
  }

  var path: String {
    switch self {
    case .refreshTokens:
      "/auth/refreshToken"
    }
  }

  var method: Moya.Method {
    switch self {
    case .refreshTokens:
      .post
    }
  }

  var task: Moya.Task {
    switch self {
    case .refreshTokens(let refreshToken):
        .requestParameters(
          parameters: ["refreshToken": "\(refreshToken)"],
          encoding: JSONEncoding.default
        )
    }
  }

  var headers: [String : String]? {
    return [
      "Origin": "taxi.sparcs.org",
      "Content-Type": "application/json"
    ]
  }
}
