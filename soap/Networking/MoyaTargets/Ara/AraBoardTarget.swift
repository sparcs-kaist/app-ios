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
  case fetchPosts(boardID: Int, page: Int)
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
    }
  }

  var method: Moya.Method {
    switch self {
    case .fetchBoards, .fetchPosts:
      .get
    }
  }

  var task: Moya.Task {
    switch self {
    case .fetchBoards:
      .requestPlain
    case .fetchPosts(let boardID, let page):
        .requestParameters(
          parameters: ["parent_board": boardID, "page": page, "page_size": 30],
          encoding: URLEncoding.queryString
        )
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
