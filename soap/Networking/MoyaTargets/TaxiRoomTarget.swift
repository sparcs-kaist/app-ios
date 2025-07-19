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
  case commitSettlement(roomID: String)
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
    case .commitSettlement:
      "/rooms/commitSettlement"
    }
  }

  var method: Moya.Method {
    switch self {
    case .fetchRooms, .fetchMyRooms, .fetchLocations:
      .get
    case .createRoom, .joinRoom, .commitSettlement:
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
    case .commitSettlement(let roomID):
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
