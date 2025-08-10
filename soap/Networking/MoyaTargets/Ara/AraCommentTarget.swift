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
    }
  }

  var method: Moya.Method {
    switch self {
    case .upvoteComment, .downvoteComment, .cancelVote:
        .post
    }
  }

  var task: Moya.Task {
    switch self {
    case .upvoteComment, .downvoteComment, .cancelVote:
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
