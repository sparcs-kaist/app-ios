//
//  FeedUserTarget.swift
//  soap
//
//  Created by Soongyu Kwon on 17/08/2025.
//

import Foundation
import Moya

public enum FeedUserTarget {
  case getUser
}

extension FeedUserTarget: TargetType, AccessTokenAuthorizable {
  public var baseURL: URL {
    BackendURL.feedBackendURL
  }

  public var path: String {
    "/me"
  }

  public var method: Moya.Method {
    .get
  }

  public var task: Moya.Task {
    .requestPlain
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
