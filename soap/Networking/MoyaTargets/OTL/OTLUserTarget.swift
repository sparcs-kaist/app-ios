//
//  OTLUserTarget.swift
//  soap
//
//  Created by Soongyu Kwon on 28/09/2025.
//

import Foundation
import Moya

enum OTLUserTarget {
  case register(ssoInfo: String)
  case fetchUserInfo
}

extension OTLUserTarget: TargetType, AccessTokenAuthorizable {
  var baseURL: URL {
    Constants.otlBackendURL
  }

  var path: String {
    switch self {
    case .register:
      "/session/register-oneapp"
    case .fetchUserInfo:
      "/session/info"
    }
  }

  var method: Moya.Method {
    switch self {
    case .register:
      .post
    case .fetchUserInfo:
      .get
    }
  }

  var task: Moya.Task {
    switch self {
    case .register(let ssoInfo):
        .requestParameters(parameters: ["sso_info": ssoInfo], encoding: JSONEncoding.default)
    case .fetchUserInfo:
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
