//
//  FeedUserTarget.swift
//  soap
//
//  Created by Soongyu Kwon on 17/08/2025.
//

import Foundation
import Moya

public enum FeedUserTarget {
  case register(ssoInfo: String)
  case getUser
}

extension FeedUserTarget: TargetType, AccessTokenAuthorizable {
  public var baseURL: URL {
    BackendURL.feedBackendURL
  }

  public var path: String {
    switch self {
    case .register:
      "/auth/bootstrap"
    case .getUser:
      "/me"
    }
  }

  public var method: Moya.Method {
    switch self {
    case .register:
      .post
    case .getUser:
      .get
    }
  }

  public var task: Moya.Task {
    switch self {
    case .register(let ssoInfo):
        .requestParameters(parameters: [
          "sso_info": ssoInfo
        ], encoding: JSONEncoding.default)
    case .getUser:
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
