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
  case fetchLocations
  case createRoom(with: TaxiCreateRoomRequestDTO)
}

extension TaxiRoomTarget: TargetType, AccessTokenAuthorizable {
  var baseURL: URL {
    Constants.taxiBackendURL
  }

  var path: String {
    switch self {
    case .fetchRooms:
      "/rooms/search"
    case .fetchLocations:
      "/locations"
    case .createRoom:
      "/rooms/create"
    }
  }

  var method: Moya.Method {
    switch self {
    case .fetchRooms, .fetchLocations:
      .get
    case .createRoom:
      .post
    }
  }

  var task: Moya.Task {
    switch self {
    case .fetchRooms, .fetchLocations:
      .requestPlain
    case .createRoom(let request):
      .requestJSONEncodable(request)
    }
  }

  var headers: [String: String]? {
    switch self {
    case .fetchRooms, .fetchLocations, .createRoom:
      [
        "Origin": "sparcsapp",
        "Content-Type": "application/json"
      ]
    }
  }

  var authorizationType: Moya.AuthorizationType? {
    .bearer
  }
}
