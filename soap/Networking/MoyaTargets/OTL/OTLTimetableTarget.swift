//
//  OTLTimetableTarget.swift
//  soap
//
//  Created by Soongyu Kwon on 29/09/2025.
//

import Foundation
import Moya

enum OTLTimetableTarget {
  case fetchTables(userID: Int, year: Int, semester: Int)
  case createTable(userID: Int, year: Int, semester: Int)
  case fetchSemesters
  case fetchCurrentSemester
}

extension OTLTimetableTarget: TargetType, AccessTokenAuthorizable {
  var baseURL: URL {
    Constants.otlBackendURL
  }

  var path: String {
    switch self {
    case .fetchTables(let userID, _, _):
      "/api/users/\(userID)/timetables"
    case .createTable(let userID, _, _):
      "/api/users/\(userID)/timetables"
    case .fetchSemesters:
      "/api/semesters"
    case .fetchCurrentSemester:
      "/api/semesters/current"
    }
  }

  var method: Moya.Method {
    switch self {
    case .fetchTables, .fetchSemesters, .fetchCurrentSemester:
        .get
    case .createTable:
        .post
    }
  }

  var task: Moya.Task {
    switch self {
    case .fetchTables(_, let year, let semester):
        .requestParameters(parameters: [
          "year": year,
          "semester": semester,
          "order": "arrange_order"
        ], encoding: URLEncoding.default)
    case .createTable(_, let year, let semester):
        .requestParameters(parameters: [
          "year": year,
          "semester": semester,
          "lectures": []
        ], encoding: JSONEncoding.default)
    case .fetchSemesters:
        .requestPlain
    case .fetchCurrentSemester:
        .requestPlain
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
