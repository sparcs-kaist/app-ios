//
//  TaxiRoomTarget.swift
//  soap
//
//  Created by Soongyu Kwon on 12/07/2025.
//

import Foundation
import Moya

enum TaxiRoomTarget {
  case fetchRooms
  case fetchMyRooms
  case fetchLocations
  case createRoom(with: TaxiCreateRoomRequestDTO)
  case joinRoom(roomID: String)
  case leaveRoom(roomID: String)
  case commitSettlement(roomID: String)
  case commitPayment(roomID: String)
}

extension TaxiRoomTarget: TargetType, AccessTokenAuthorizable {
  var baseURL: URL {
    Constants.taxiBackendURL
  }

  var path: String {
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
    case .commitSettlement:
      "/rooms/commitSettlement"
    case .commitPayment:
      "/rooms/commitPayment"
    }
  }

  var method: Moya.Method {
    switch self {
    case .fetchRooms, .fetchMyRooms, .fetchLocations:
      .get
    case .createRoom, .joinRoom, .leaveRoom, .commitSettlement, .commitPayment:
      .post
    }
  }

  var task: Moya.Task {
    switch self {
    case .fetchRooms, .fetchMyRooms, .fetchLocations:
      .requestPlain
    case .createRoom(let request):
      .requestJSONEncodable(request)
    case .joinRoom(let roomID):
        .requestParameters(parameters: ["roomId": roomID], encoding: JSONEncoding.default)
    case .leaveRoom(let roomID):
        .requestParameters(parameters: ["roomId": roomID], encoding: JSONEncoding.default)
    case .commitSettlement(let roomID):
        .requestParameters(parameters: ["roomId": roomID], encoding: JSONEncoding.default)
    case .commitPayment(let roomID):
        .requestParameters(parameters: ["roomId": roomID], encoding: JSONEncoding.default)
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
