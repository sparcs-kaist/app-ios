//
//  AraBoardTarget.swift
//  soap
//
//  Created by Soongyu Kwon on 05/08/2025.
//

import Foundation
import Moya

enum AraBoardTarget {
  case getBoards
}

extension AraBoardTarget: TargetType, AccessTokenAuthorizable {
  var baseURL: URL {
    Constants.araBackendURL
  }

  var path: String {
    switch self {
    case .getBoards:
      "/boards/"
    }
  }

  var method: Moya.Method {
    switch self {
    case .getBoards:
      .get
    }
  }

  var task: Moya.Task {
    switch self {
    case .getBoards:
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
