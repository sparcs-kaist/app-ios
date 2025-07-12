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
}

extension TaxiRoomTarget: TargetType {
  var baseURL: URL {
    Constants.taxiBackendURL
  }

  var path: String {
    switch self {
    case .fetchRooms:
      "/rooms/search"
    case .fetchLocations:
      "/locations"
    }
  }

  var method: Moya.Method {
    switch self {
    case .fetchRooms, .fetchLocations:
      .get
    }
  }

  var task: Moya.Task {
    switch self {
    case .fetchRooms, .fetchLocations:
      .requestPlain
    }
  }

  var headers: [String: String]? {
    switch self {
    case .fetchRooms, .fetchLocations:
      [
        "Origin": "sparcsapp",
        "Content-Type": "application/json"
      ]
    }
  }
}
