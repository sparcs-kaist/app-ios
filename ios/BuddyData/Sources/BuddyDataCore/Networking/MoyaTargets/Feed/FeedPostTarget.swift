//
//  FeedPostTarget.swift
//  soap
//
//  Created by Soongyu Kwon on 17/08/2025.
//

import Foundation
import Moya
import BuddyDomain

public enum FeedPostTarget {
  case fetchPosts(cursor: String?, limit: Int)
  case writePost(request: FeedPostRequestDTO)
  case delete(postID: String)
  case vote(postID: String, type: FeedVoteType)
  case deleteVote(postID: String)
  case reportPost(postID: String, reason: String, detail: String)
}

extension FeedPostTarget: TargetType, AccessTokenAuthorizable {
  public var baseURL: URL {
    BackendURL.feedBackendURL
  }

  public var path: String {
    switch self {
    case .fetchPosts, .writePost:
      "/posts"
    case .delete(let postID):
      "/posts/\(postID)"
    case .vote(let postID, _):
      "/posts/\(postID)/vote"
    case .deleteVote(let postID):
      "/posts/\(postID)/vote"
    case .reportPost(let postID, _, _):
      "/posts/\(postID)/report"
    }
  }

  public var method: Moya.Method {
    switch self {
    case .fetchPosts:
      .get
    case .writePost, .vote, .reportPost:
      .post
    case .delete, .deleteVote:
      .delete
    }
  }

  public var task: Moya.Task {
    switch self {
    case .fetchPosts(let cursor, let limit):
      var parameters: [String: Any] = [:]
      if let cursor {
        parameters["cursor"] = cursor
      }
      parameters["limit"] = limit
      return .requestParameters(parameters: parameters, encoding: URLEncoding.queryString)
    case .writePost(let request):
      return .requestJSONEncodable(request)
    case .delete(_):
      return .requestPlain
    case .vote(_, let type):
      return .requestParameters(parameters: ["vote": type.rawValue], encoding: JSONEncoding.default)
    case .deleteVote(_):
      return .requestPlain
    case .reportPost(_, let reason, let detail):
      return .requestParameters(parameters: ["reason": reason, "detail": detail], encoding: JSONEncoding.default)
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
