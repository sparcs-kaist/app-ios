//
//  FriendTarget.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 28/09/2026.
//

import Foundation
import Moya

public enum FriendTarget {
  case fetchFriends
  case addFriend(code: String)
  case deleteFriend(id: Int)
  case setFavorite(id: Int, isFavorite: Bool)
  case fetchMyCode
}

extension FriendTarget: TargetType, AccessTokenAuthorizable {
  public var baseURL: URL {
    BackendURL.otlBackendURL
  }

  public var path: String {
    switch self {
    case .fetchFriends, .addFriend:
      "/api/v2/friends"
    case .deleteFriend(let id):
      "/api/v2/friends/\(id)"
    case .setFavorite(let id, _):
      "/api/v2/friends/\(id)/favorite"
    case .fetchMyCode:
      "/api/v2/friends/code"
    }
  }

  public var method: Moya.Method {
    switch self {
    case .fetchFriends, .fetchMyCode:
      .get
    case .addFriend:
      .post
    case .deleteFriend:
      .delete
    case .setFavorite:
      .patch
    }
  }

  public var task: Moya.Task {
    switch self {
    case .addFriend(let code):
      .requestParameters(parameters: ["code": code], encoding: JSONEncoding.default)
    case .setFavorite(_, let isFavorite):
      .requestParameters(parameters: ["isFavorite": isFavorite], encoding: JSONEncoding.default)
    case .fetchFriends, .deleteFriend, .fetchMyCode:
      .requestPlain
    }
  }

  public var headers: [String: String]? {
    var headers = [
      "Content-Type": "application/json"
    ]

    #if DEBUG
    if !OTLDebugSecrets.key.isEmpty {
      headers["X-SID-AUTH-TOKEN"] = OTLDebugSecrets.key
    }
    #endif

    return headers
  }

  public var authorizationType: Moya.AuthorizationType? {
    .bearer
  }
}
