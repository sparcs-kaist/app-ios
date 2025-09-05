//
//  FeedUserTarget.swift
//  soap
//
//  Created by Soongyu Kwon on 17/08/2025.
//

import Foundation
import Moya

enum FeedUserTarget {
  case register(ssoInfo: String)
  case getUser
}

extension FeedUserTarget: TargetType, AccessTokenAuthorizable {
  var baseURL: URL {
    Constants.feedBackendURL
  }

  var path: String {
    switch self {
    case .register:
      "/auth/bootstrap"
    case .getUser:
      "/me"
    }
  }

  var method: Moya.Method {
    switch self {
    case .register:
      .post
    case .getUser:
      .get
    }
  }

  var task: Moya.Task {
    switch self {
    case .register(let ssoInfo):
        .requestParameters(parameters: [
          "sso_info": ssoInfo
        ], encoding: JSONEncoding.default)
    case .getUser:
        .requestPlain
    }
  }

  var headers: [String: String]? {
    [
      "Content-Type": "application/json"
    ]
  }

  var authorizationType: Moya.AuthorizationType? {
    .bearer
  }
}
