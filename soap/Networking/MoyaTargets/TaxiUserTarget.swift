//
//  TaxiUserTarget.swift
//  soap
//
//  Created by Soongyu Kwon on 12/07/2025.
//

import Foundation
import Moya

enum TaxiUserTarget {
  case fetchUserInfo
}

extension TaxiUserTarget: TargetType, AccessTokenAuthorizable {
  var baseURL: URL {
    Constants.taxiBackendURL
  }

  var path: String {
    switch self {
    case .fetchUserInfo:
      "/logininfo"
    }
  }

  var method: Moya.Method {
    switch self {
    case .fetchUserInfo:
      .get
    }
  }

  var task: Moya.Task {
    switch self {
    case .fetchUserInfo:
      .requestPlain
    }
  }

  var headers: [String: String]? {
    switch self {
    case .fetchUserInfo:      [
        "Origin": "sparcsapp",
        "Content-Type": "application/json"
      ]
    }
  }

  var authorizationType: Moya.AuthorizationType? {
    .bearer
  }
}
