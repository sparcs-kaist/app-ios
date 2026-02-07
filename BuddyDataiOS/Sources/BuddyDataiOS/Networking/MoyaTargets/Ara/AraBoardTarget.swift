//
//  AraBoardTarget.swift
//  soap
//
//  Created by Soongyu Kwon on 05/08/2025.
//

import Foundation
import Moya
import BuddyDomain
import BuddyDataCore

public enum AraBoardTarget {
  case fetchBoards
  case fetchPosts(type: PostListType, page: Int, pageSize: Int, searchKeyword: String?)
  case fetchPost(origin: PostOrigin?, postID: Int)
  case fetchBookmarks(page: Int, pageSize: Int)
  case uploadImage(imageData: Data)
  case writePost(_ request: AraPostRequestDTO)
  case upvote(postID: Int)
  case downvote(postID: Int)
  case cancelVote(postID: Int)
  case report(postID: Int, type: AraContentReportType)
  case delete(postID: Int)
  case addBookmark(postId: Int)
  case removeBookmark(scrapId: Int)
}

extension AraBoardTarget: TargetType, AccessTokenAuthorizable {
  public var baseURL: URL {
    BackendURL.araBackendURL
  }

  public var path: String {
    switch self {
    case .fetchBoards:
      "/boards/"
    case .fetchPosts, .writePost:
      "/articles/"
    case .fetchPost(_, let postID):
      "/articles/\(postID)/"
    case .fetchBookmarks, .addBookmark:
      "/scraps/"
    case .upvote(let postID):
      "/articles/\(postID)/vote_positive/"
    case .downvote(let postID):
      "/articles/\(postID)/vote_negative/"
    case .cancelVote(let postID):
      "/articles/\(postID)/vote_cancel/"
    case .report:
      "/reports/"
    case .uploadImage:
      "/attachments/"
    case .delete(let postID):
      "/articles/\(postID)/"
    case .removeBookmark(let scrapId):
      "/scraps/\(scrapId)/"
    }
  }

  public var method: Moya.Method {
    switch self {
    case .fetchBoards, .fetchPosts, .fetchPost, .fetchBookmarks:
      .get
    case .writePost, .upvote, .downvote, .cancelVote, .report, .uploadImage, .addBookmark:
      .post
    case .delete, .removeBookmark:
      .delete
    }
  }

  public var task: Moya.Task {
    switch self {
    case .fetchBoards, .upvote, .downvote, .cancelVote:
      return .requestPlain
    case .fetchPosts(let type, let page, let pageSize, let searchKeyword):
      var parameters: [String: Any] = [
        "page": page,
        "page_size": pageSize
      ]

      switch type {
      case .all:
        break // pass
      case .board(let boardID):
        parameters["parent_board"] = boardID
      case .user(let userID):
        parameters["created_by"] = userID
      }

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
    case .fetchBookmarks(let page, let pageSize):
      return .requestParameters(parameters: ["page": page, "page_size": pageSize], encoding: URLEncoding.queryString)
    case .uploadImage(let imageData):
      let imageMultipart = MultipartFormData(
        provider: .data(imageData),
        name: "file",
        fileName: "image.png",
        mimeType: "image/png"
      )
      return .uploadMultipart([imageMultipart])
    case .writePost(let request):
      return .requestJSONEncodable(request)
    case .report(let postID, let type):
      return .requestParameters(parameters: [
        "parent_article": postID,
        "type": "others",
        "content": type.rawValue
      ], encoding: JSONEncoding.default)
    case .delete, .removeBookmark:
      return .requestPlain
    case .addBookmark(let postId):
      return .requestParameters(parameters: ["parent_article": postId], encoding: JSONEncoding.default)
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
