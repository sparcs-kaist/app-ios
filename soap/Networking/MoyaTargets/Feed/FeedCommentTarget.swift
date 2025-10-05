//
//  FeedCommentTarget.swift
//  soap
//
//  Created by Soongyu Kwon on 25/08/2025.
//

import Foundation
import Moya
import BuddyDomain

enum FeedCommentTarget {
  case fetchComments(postID: String)
  case writeComment(postID: String, request: FeedCommentRequestDTO)
  case writeReply(commentID: String, request: FeedCommentRequestDTO)
  case delete(commentID: String)
  case vote(commentID: String, type: FeedVoteType)
  case deleteVote(commentID: String)
  case reportComment(commentID: String, reason: String, detail: String)
}

extension FeedCommentTarget: TargetType, AccessTokenAuthorizable {
  var baseURL: URL {
    Constants.feedBackendURL
  }

  var path: String {
    switch self {
    case .fetchComments(let postID):
      "/posts/\(postID)/comments"
    case .writeComment(let postID, _):
      "/posts/\(postID)/comments"
    case .writeReply(let commentID, _):
      "/comments/\(commentID)/replies"
    case .delete(let commentID):
      "/comments/\(commentID)"
    case .vote(let commentID, _):
      "/comments/\(commentID)/vote"
    case .deleteVote(let commentID):
      "/comments/\(commentID)/vote"
    case .reportComment(let commentID, _, _):
      "/comments/\(commentID)/report"
    }
  }

  var method: Moya.Method {
    switch self {
    case .fetchComments:
      .get
    case .writeComment, .writeReply, .vote, .reportComment:
      .post
    case .delete, .deleteVote:
      .delete
    }
  }

  var task: Moya.Task {
    switch self {
    case .fetchComments:
      .requestPlain
    case .writeComment(_, let request):
      .requestJSONEncodable(request)
    case .writeReply(_, let request):
      .requestJSONEncodable(request)
    case .delete(_):
      .requestPlain
    case .vote(_, let type):
      .requestParameters(parameters: ["vote": type.rawValue], encoding: JSONEncoding.default)
    case .deleteVote:
      .requestPlain
    case .reportComment(_, let reason, let detail):
      .requestParameters(parameters: ["reason": reason, "detail": detail], encoding: JSONEncoding.default)
    }
  }

  var headers: [String : String]? {
    [
      "Content-Type": "application/json"
    ]
  }

  var authorizationType: Moya.AuthorizationType? {
    .bearer
  }
}
