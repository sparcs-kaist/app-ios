//
//  AraCommentTarget.swift
//  soap
//
//  Created by Soongyu Kwon on 11/08/2025.
//

import Foundation
import Moya

enum AraCommentTarget {
  case upvoteComment(commentID: Int)
  case downvoteComment(commentID: Int)
  case cancelVote(commentID: Int)
  case writeComment(postID: Int, content: String)
  case writeThreadedComment(commentID: Int, content: String)
  case deleteComment(commentID: Int)
  case patchComment(commentID: Int, content: String)
}

extension AraCommentTarget: TargetType, AccessTokenAuthorizable {
  var baseURL: URL {
    Constants.araBackendURL
  }

  var path: String {
    switch self {
    case .downvoteComment(let commentID):
      "/comments/\(commentID)/vote_negative/"
    case .upvoteComment(let commentID):
      "/comments/\(commentID)/vote_positive/"
    case .cancelVote(let commentID):
      "/comments/\(commentID)/vote_cancel/"
    case .writeComment, .writeThreadedComment:
      "/comments/"
    case .deleteComment(let commentID):
      "/comments/\(commentID)/"
    case .patchComment(let commentID, _):
      "/comments/\(commentID)/"
    }
  }

  var method: Moya.Method {
    switch self {
    case .upvoteComment, .downvoteComment, .cancelVote, .writeComment, .writeThreadedComment:
        .post
    case .deleteComment:
        .delete
    case .patchComment:
        .patch
    }
  }

  var task: Moya.Task {
    switch self {
    case .upvoteComment, .downvoteComment, .cancelVote:
        .requestPlain
    case .writeComment(let postID, let content):
        .requestParameters(parameters: [
          "parent_article": postID,
          "content": content,
          "name_type": 2
        ], encoding: JSONEncoding.default)
    case .writeThreadedComment(let commentID, let content):
        .requestParameters(parameters: [
          "parent_comment": commentID,
          "content": content,
          "name_type": 2
        ], encoding: JSONEncoding.default)
    case .deleteComment:
        .requestPlain
    case .patchComment(let commentID, let content):
        .requestParameters(parameters: [
          "content": content,
          "name_type": 2,
          "is_mine": true
        ], encoding: JSONEncoding.default)
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
