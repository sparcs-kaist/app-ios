//
//  AraBoardTarget.swift
//  soap
//
//  Created by Soongyu Kwon on 05/08/2025.
//

import Foundation
import Moya

enum AraBoardTarget {
  case fetchBoards
  case fetchPosts(boardID: Int, page: Int, pageSize: Int)

  enum PostOrigin {
    case all
    case board
    case topic(topicID: String)
  }
  case fetchPost(origin: PostOrigin?, postID: Int)
  case writePost(_ request: AraPostRequestDTO)
  case upvotePost(postID: Int)
  case downvotePost(postID: Int)
  case cancelVote(postID: Int)
}

extension AraBoardTarget: TargetType, AccessTokenAuthorizable {
  var baseURL: URL {
    Constants.araBackendURL
  }

  var path: String {
    switch self {
    case .fetchBoards:
      "/boards/"
    case .fetchPosts, .writePost:
      "/articles/"
    case .fetchPost(_, let postID):
      "/articles/\(postID)/"
    case .upvotePost(let postID):
      "/articles/\(postID)/vote_positive/"
    case .downvotePost(let postID):
      "/articles/\(postID)/vote_negative/"
    case .cancelVote(let postID):
      "/articles/\(postID)/vote_cancel/"
    }
  }

  var method: Moya.Method {
    switch self {
    case .fetchBoards, .fetchPosts, .fetchPost:
      .get
    case .writePost, .upvotePost, .downvotePost, .cancelVote:
      .post
    }
  }

  var task: Moya.Task {
    switch self {
    case .fetchBoards, .upvotePost, .downvotePost, .cancelVote:
      return .requestPlain
    case .fetchPosts(let boardID, let page, let pageSize):
      return .requestParameters(
        parameters: ["parent_board": boardID, "page": page, "page_size": pageSize],
        encoding: URLEncoding.queryString
      )
    case .fetchPost(let origin, _):
      var parameters: [String: Any] = [:]
      if let origin = origin {
        switch origin {
        case .all:
          parameters["from_view"] = "all"
        case .board:
          parameters["from_view"] = "board"
        case .topic(let topicID):
          parameters["from_view"] = "topic"
          parameters["topic_id"] = topicID
        }

        parameters["current"] = 1
      }

      return .requestParameters(parameters: parameters, encoding: URLEncoding.queryString)
    case .writePost(let request):
      return .requestJSONEncodable(request)
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
