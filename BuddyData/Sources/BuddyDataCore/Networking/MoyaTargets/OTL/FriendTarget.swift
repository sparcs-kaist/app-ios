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
  case fetchSharedSemesters(friendID: Int)
  case fetchSharedTimetable(friendID: Int, year: Int, semester: Int)
  case fetchLectureFriends(lectureID: Int)
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
    case .fetchSharedSemesters(let friendID):
      "/api/v2/friends/\(friendID)/timetables/shared/semesters"
    case .fetchSharedTimetable(let friendID, _, _):
      "/api/v2/friends/\(friendID)/timetables/shared"
    case .fetchLectureFriends(let lectureID):
      "/api/v2/friends/lectures/\(lectureID)/overlaps"
    }
  }

  public var method: Moya.Method {
    switch self {
    case .fetchFriends, .fetchMyCode, .fetchSharedSemesters, .fetchSharedTimetable, .fetchLectureFriends:
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
    case .fetchSharedTimetable(_, let year, let semester):
      .requestParameters(parameters: ["year": year, "semester": semester], encoding: URLEncoding.queryString)
    case .fetchFriends, .deleteFriend, .fetchMyCode, .fetchSharedSemesters, .fetchLectureFriends:
      .requestPlain
    }
  }

  public var headers: [String: String]? {
    var headers = [
      "Content-Type": "application/json",
      // Lecture and department names in a friend's timetable follow it, like the other OTL targets.
      "Accept-Language": Bundle.main.preferredLocalizations.first ?? "ko"
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
