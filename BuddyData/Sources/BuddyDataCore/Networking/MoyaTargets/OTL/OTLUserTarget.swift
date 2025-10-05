//
//  OTLUserTarget.swift
//  soap
//
//  Created by Soongyu Kwon on 28/09/2025.
//

import Foundation
import Moya

public enum OTLUserTarget {
  case register(ssoInfo: String)
  case fetchUserInfo
}

extension OTLUserTarget: TargetType, AccessTokenAuthorizable {
  public var baseURL: URL {
    BackendURL.otlBackendURL
  }

  public var path: String {
    switch self {
    case .register:
      "/session/register-oneapp"
    case .fetchUserInfo:
      "/session/info"
    }
  }

  public var method: Moya.Method {
    switch self {
    case .register:
      .post
    case .fetchUserInfo:
      .get
    }
  }

  public var task: Moya.Task {
    switch self {
    case .register(let ssoInfo):
        .requestParameters(parameters: ["sso_info": ssoInfo], encoding: JSONEncoding.default)
    case .fetchUserInfo:
        .requestPlain
    }
  }

  public var headers: [String: String]? {
    [
      "Content-Type": "application/json"
    ]
  }

  public var authorizationType: Moya.AuthorizationType? {
    .bearer
  }
}
