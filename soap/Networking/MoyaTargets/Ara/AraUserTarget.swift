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
  case agreeTOS(userID: Int)
  case fetchMe
  case patchMe(userID: Int, allowNSFW: Bool, allowPolitical: Bool)
}

extension AraUserTarget: TargetType, AccessTokenAuthorizable {
  var baseURL: URL {
    Constants.araBackendURL
  }

  var path: String {
    switch self {
    case .register:
      "/users/oneapp-login/"
    case .agreeTOS(let userID):
      "/user_profiles/\(userID)/agree_terms_of_service/"
    case .fetchMe:
      "/me"
    case .patchMe(let userID, _, _):
      "/user_profiles/\(userID)/"
    }
  }

  var method: Moya.Method {
    switch self {
    case .register:
      .post
    case .agreeTOS, .patchMe:
        .patch
    case .fetchMe:
      .get
    }
  }

  var task: Moya.Task {
    switch self {
    case .register(let ssoInfo):
        .requestParameters(parameters: ["ssoInfo": ssoInfo], encoding: JSONEncoding.default)
    case .agreeTOS, .fetchMe:
        .requestPlain
    case .patchMe(_, let allowNSFW, let allowPolitical):
        .requestParameters(parameters: ["see_sexual": allowNSFW, "see_social": allowPolitical], encoding: JSONEncoding.default)
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
