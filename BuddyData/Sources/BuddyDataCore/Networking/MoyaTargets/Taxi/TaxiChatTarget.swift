//
//  TaxiRoomTarget.swift
//  soap
//
//  Created by Soongyu Kwon on 12/07/2025.
//

import Foundation
import Moya

public enum TaxiChatTarget {
  case fetchChats(roomID: String)
  case fetchChatsBefore(roomID: String, date: String)
  case fetchChatsAfter(roomID: String, date: String)
  case sendChat(request: TaxiChatRequestDTO)
  case readChat(roomID: String)
  case getPresignedURL(roomID: String)
  case uploadImage(url: String, imageData: Data)    // this goes to AWS S3
  case notifyImageUploadComplete(id: String)
}

extension TaxiChatTarget: TargetType, AccessTokenAuthorizable {
  public var baseURL: URL {
    switch self {
    case .uploadImage(let url, _):
      URL(string: url)!
    default:
      BackendURL.taxiBackendURL
    }
  }

  public var path: String {
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
    case .uploadImage:
      ""
    case .notifyImageUploadComplete:
      "/chats/uploadChatImg/done"
    }
  }

  public var method: Moya.Method {
    switch self {
    case .uploadImage:
        .put
    default:
        .post
    }
  }

  public var task: Moya.Task {
    switch self {
    case .fetchChats(let roomID):
      return .requestParameters(parameters: ["roomId": roomID], encoding: JSONEncoding.default)
    case .fetchChatsBefore(let roomID, let date):
      return .requestParameters(parameters: ["roomId": roomID, "lastMsgDate": date], encoding: JSONEncoding.default)
    case .fetchChatsAfter(let roomID, let date):
      return .requestParameters(parameters: ["roomId": roomID, "lastMsgDate": date], encoding: JSONEncoding.default)
    case .sendChat(let request):
      return .requestJSONEncodable(request)
    case .readChat(let roomID):
      return .requestParameters(parameters: ["roomId": roomID], encoding: JSONEncoding.default)
    case .getPresignedURL(let roomID):
      return .requestParameters(parameters: ["roomId": roomID, "type": "image/png"], encoding: JSONEncoding.default)
    case .uploadImage(_, let imageData):
      return .requestData(imageData)
    case .notifyImageUploadComplete(let id):
      return .requestParameters(parameters: ["id": id], encoding: JSONEncoding.default)
    }
  }

  public var headers: [String: String]? {
    switch self {
    case .uploadImage:
      [
        "Origin": "sparcsapp",
        "Content-Type": "image/png"
      ]
    default:
      [
        "Origin": "sparcsapp",
        "Content-Type": "application/json"
      ]
    }
  }

  public var authorizationType: Moya.AuthorizationType? {
    switch self {
    case .uploadImage:
      nil
    default:
      .bearer
    }
  }
}
