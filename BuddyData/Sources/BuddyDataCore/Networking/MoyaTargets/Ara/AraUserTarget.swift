//
//  AraUserTarget.swift
//  soap
//
//  Created by Soongyu Kwon on 01/08/2025.
//

import Foundation
import Moya

public enum AraUserTarget {
  case register(ssoInfo: String)
  case agreeTOS(userID: Int)
  case fetchMe
  case updateUser(userID: Int, params: [String: Any])
  case block(userID: Int)
  case unblock(userID: Int)
  case fetchBlocks(page: Int, pageSize: Int)
}

extension AraUserTarget: TargetType, AccessTokenAuthorizable {
  public var baseURL: URL {
    BackendURL.araBackendURL
  }

  public var path: String {
    switch self {
    case .register:
      "/users/oneapp-login/"
    case .agreeTOS(let userID):
      "/user_profiles/\(userID)/agree_terms_of_service/"
    case .fetchMe:
      "/me"
    case .updateUser(let userID, _):
      "/user_profiles/\(userID)/"
    case .block, .fetchBlocks:
      "/blocks/"
    case .unblock:
      "/blocks/without_id/"
    }
  }

  public var method: Moya.Method {
    switch self {
    case .register, .block, .unblock:
      .post
    case .agreeTOS, .updateUser:
        .patch
    case .fetchMe, .fetchBlocks:
      .get
    }
  }

  public var task: Moya.Task {
    switch self {
    case .register(let ssoInfo):
        .requestParameters(parameters: ["ssoInfo": ssoInfo], encoding: JSONEncoding.default)
    case .agreeTOS, .fetchMe:
        .requestPlain
    case .updateUser(_, let params):
        .requestParameters(parameters: params, encoding: JSONEncoding.default)
    case .block(let userID):
        .requestParameters(parameters: ["user": userID], encoding: JSONEncoding.default)
    case .unblock(let userID):
        .requestParameters(parameters: ["blocked": userID], encoding: JSONEncoding.default)
    case .fetchBlocks(let page, let pageSize):
        .requestParameters(parameters: ["page": page, "page_size": pageSize], encoding: URLEncoding.queryString)
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
