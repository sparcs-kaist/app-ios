//
//  AraUserTarget.swift
//  soap
//
//  Created by Soongyu Kwon on 01/08/2025.
//

import Foundation
import Moya

enum AraUserTarget {
  case register(ssoInfo: String)
}

extension AraUserTarget: TargetType, AccessTokenAuthorizable {
  var baseURL: URL {
    Constants.araBackendURL
  }

  var path: String {
    switch self {
    case .register:
      "/users/oneapp-login/"
    }
  }

  var method: Moya.Method {
    switch self {
    case .register:
      .post
    }
  }

  var task: Moya.Task {
    switch self {
    case .register(let ssoInfo):
        .requestParameters(parameters: ["ssoInfo": ssoInfo], encoding: JSONEncoding.default)
    }
  }

  var headers: [String: String]? {
    [
      "Origin": "sparcsapp",
      "Content-Type": "application/json"
    ]
  }

  var authorizationType: Moya.AuthorizationType? {
    .bearer
  }
}
