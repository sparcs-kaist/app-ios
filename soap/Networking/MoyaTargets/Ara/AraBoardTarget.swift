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
  case fetchPosts(boardID: Int, page: Int, pageSize: Int, searchKeyword: String?)

  enum PostOrigin {
    case all
    case board
    case topic(topicID: String)
  }
  case fetchPost(origin: PostOrigin?, postID: Int)
  case writePost(_ request: AraPostRequestDTO)
  case upvote(postID: Int)
  case downvote(postID: Int)
  case cancelVote(postID: Int)
  case report(postID: Int, type: AraContentReportType)
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
    case .upvote(let postID):
      "/articles/\(postID)/vote_positive/"
    case .downvote(let postID):
      "/articles/\(postID)/vote_negative/"
    case .cancelVote(let postID):
      "/articles/\(postID)/vote_cancel/"
    case .report:
      "/reports/"
    }
  }

  var method: Moya.Method {
    switch self {
    case .fetchBoards, .fetchPosts, .fetchPost:
      .get
    case .writePost, .upvote, .downvote, .cancelVote, .report:
      .post
    }
  }

  var task: Moya.Task {
    switch self {
    case .fetchBoards, .upvote, .downvote, .cancelVote:
      return .requestPlain
    case .fetchPosts(let boardID, let page, let pageSize, let searchKeyword):
      var parameters: [String: Any] = [
        "parent_board": boardID,
        "page": page,
        "page_size": pageSize
      ]
      if let searchKeyword {
        parameters["main_search__contains"] = searchKeyword
      }

      return .requestParameters(
        parameters: parameters,
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
    case .report(let postID, let type):
      return .requestParameters(parameters: [
        "parent_article": postID,
        "type": "others",
        "content": type.rawValue
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
