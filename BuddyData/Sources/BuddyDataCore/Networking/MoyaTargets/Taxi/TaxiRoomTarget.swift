//
//  TaxiRoomTarget.swift
//  soap
//
//  Created by Soongyu Kwon on 12/07/2025.
//

import Foundation
import Moya

public enum TaxiRoomTarget {
  case fetchRooms
  case fetchMyRooms
  case fetchLocations
  case createRoom(with: TaxiCreateRoomRequestDTO)
  case joinRoom(roomID: String)
  case leaveRoom(roomID: String)
  case getRoom(roomID: String)
  case getPublicRoom(roomID: String)
  case commitSettlement(roomID: String)
  case commitPayment(roomID: String)
}

extension TaxiRoomTarget: TargetType, AccessTokenAuthorizable {
  public var baseURL: URL {
    BackendURL.taxiBackendURL
  }

  public var path: String {
    switch self {
    case .fetchRooms:
      "/rooms/search"
    case .fetchMyRooms:
      "/rooms/searchByUser"
    case .fetchLocations:
      "/locations"
    case .createRoom:
      "/rooms/create"
    case .joinRoom:
      "/rooms/join"
    case .leaveRoom:
      "/rooms/abort"
    case .getRoom:
      "/rooms/info"
    case .getPublicRoom:
      "/rooms/publicInfo"
    case .commitSettlement:
      "/rooms/commitSettlement"
    case .commitPayment:
      "/rooms/commitPayment"
    }
  }

  public var method: Moya.Method {
    switch self {
    case .fetchRooms, .fetchMyRooms, .getRoom, .fetchLocations, .getPublicRoom:
      .get
    case .createRoom, .joinRoom, .leaveRoom, .commitSettlement, .commitPayment:
      .post
    }
  }

  public var task: Moya.Task {
    switch self {
    case .fetchRooms:
      .requestPlain
    case .fetchMyRooms, .fetchLocations:
      .requestPlain
    case .createRoom(let request):
      .requestJSONEncodable(request)
    case .joinRoom(let roomID):
      .requestParameters(parameters: ["roomId": roomID], encoding: JSONEncoding.default)
    case .leaveRoom(let roomID):
      .requestParameters(parameters: ["roomId": roomID], encoding: JSONEncoding.default)
    case .getRoom(let roomID):
      .requestParameters(parameters: ["id": roomID], encoding: URLEncoding.queryString)
    case .getPublicRoom(let roomID):
        .requestParameters(parameters: ["id": roomID], encoding: URLEncoding.queryString)
    case .commitSettlement(let roomID):
      .requestParameters(parameters: ["roomId": roomID], encoding: JSONEncoding.default)
    case .commitPayment(let roomID):
      .requestParameters(parameters: ["roomId": roomID], encoding: JSONEncoding.default)
    }
  }

  public var headers: [String: String]? {
    [
      "Origin": "sparcsapp",
      "Content-Type": "application/json"
    ]
  }

  public var authorizationType: Moya.AuthorizationType? {
    .bearer
  }
}
