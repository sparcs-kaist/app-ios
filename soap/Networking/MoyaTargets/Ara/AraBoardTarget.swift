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
}

extension AraBoardTarget: TargetType, AccessTokenAuthorizable {
  var baseURL: URL {
    Constants.araBackendURL
  }

  var path: String {
    switch self {
    case .fetchBoards:
      "/boards/"
    case .fetchPosts:
      "/articles/"
    case .fetchPost(_, let postID):
      "/articles/\(postID)/"
    }
  }

  var method: Moya.Method {
    switch self {
    case .fetchBoards, .fetchPosts, .fetchPost:
      .get
    }
  }

  var task: Moya.Task {
    switch self {
    case .fetchBoards:
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
