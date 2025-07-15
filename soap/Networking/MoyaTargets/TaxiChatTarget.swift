//
//  TaxiRoomTarget.swift
//  soap
//
//  Created by Soongyu Kwon on 12/07/2025.
//

import Foundation
import Moya

enum TaxiChatTarget {
  case fetchChats(roomID: String)
  case fetchChatsBefore(roomID: String, date: String)
  case fetchChatsAfter(roomID: String, date: String)
  case sendChat(request: TaxiChatRequestDTO)
  case readChat(roomID: String)
  case getPresignedURL(roomID: String)
}

extension TaxiChatTarget: TargetType, AccessTokenAuthorizable {
  var baseURL: URL {
    Constants.taxiBackendURL
  }

  var path: String {
    switch self {
    case .fetchChats:
      "/chats"
    case .fetchChatsBefore:
      "/chats/load/before"
    case .fetchChatsAfter:
      "/chats/load/after"
    case .sendChat:
      "/chats/send"
    case .readChat:
      "/chats/read"
    case .getPresignedURL:
      "/chats/uploadChatImg/getPUrl"
    }
  }

  var method: Moya.Method {
    .post
  }

  var task: Moya.Task {
    switch self {
    case .fetchChats(let roomID):
        .requestParameters(parameters: ["roomId": roomID], encoding: JSONEncoding.default)
    case .fetchChatsBefore(let roomID, let date):
        .requestParameters(parameters: ["roomId": roomID, "lastMsgDate": date], encoding: JSONEncoding.default)
    case .fetchChatsAfter(let roomID, let date):
        .requestParameters(parameters: ["roomId": roomID, "lastMsgDate": date], encoding: JSONEncoding.default)
    case .sendChat(let request):
        .requestJSONEncodable(request)
    case .readChat(let roomID):
        .requestParameters(parameters: ["roomId": roomID], encoding: JSONEncoding.default)
    case .getPresignedURL(let roomID):
        .requestParameters(parameters: ["roomId": roomID, "type": "image/png"], encoding: JSONEncoding.default)
    }
  }

  var headers: [String: String]? {
    [
      "Origin": "sparcsapp",
      "Content-Type": "application/json"
    ]
  }

  var authorizationType: Moya.AuthorizationType? {
    .bearer
  }
}
