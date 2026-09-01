//
//  AraCommentTarget.swift
//  soap
//
//  Created by Soongyu Kwon on 11/08/2025.
//

import Foundation
import Moya
import BuddyDomain

public enum AraCommentTarget {
  case upvote(commentID: Int)
  case downvote(commentID: Int)
  case cancelVote(commentID: Int)
  case post(postID: Int, content: String)
  case postThreaded(commentID: Int, content: String)
  case delete(commentID: Int)
  case patch(commentID: Int, content: String)
  case report(commentID: Int, type: AraContentReportType)
}

extension AraCommentTarget: TargetType, AccessTokenAuthorizable {
  public var baseURL: URL {
    BackendURL.araBackendURL
  }

  public var path: String {
    switch self {
    case .downvote(let commentID):
      "/comments/\(commentID)/vote_negative/"
    case .upvote(let commentID):
      "/comments/\(commentID)/vote_positive/"
    case .cancelVote(let commentID):
      "/comments/\(commentID)/vote_cancel/"
    case .post, .postThreaded:
      "/comments/"
    case .delete(let commentID):
      "/comments/\(commentID)/"
    case .patch(let commentID, _):
      "/comments/\(commentID)/"
    case .report:
      "/reports/"
    }
  }

  public var method: Moya.Method {
    switch self {
    case .upvote, .downvote, .cancelVote, .post, .postThreaded, .report:
        .post
    case .delete:
        .delete
    case .patch:
        .patch
    }
  }

  public var task: Moya.Task {
    switch self {
    case .upvote, .downvote, .cancelVote:
        .requestPlain
    case .post(let postID, let content):
        .requestParameters(parameters: [
          "parent_article": postID,
          "content": content,
          "name_type": 2
        ], encoding: JSONEncoding.default)
    case .postThreaded(let commentID, let content):
        .requestParameters(parameters: [
          "parent_comment": commentID,
          "content": content,
          "name_type": 2
        ], encoding: JSONEncoding.default)
    case .delete:
        .requestPlain
    case .patch(_, let content):
        .requestParameters(parameters: [
          "content": content,
          "name_type": 2,
          "is_mine": true
        ], encoding: JSONEncoding.default)
    case .report(let commentID, let type):
        .requestParameters(parameters: [
          "parent_comment": commentID,
          "type": "others",
          "content": type.rawValue
        ], encoding: JSONEncoding.default)
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
