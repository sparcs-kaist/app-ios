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
  case deleteTable(userID: Int, timetableID: Int)
  case addLecture(userID: Int, timetableID: Int, lectureID: Int)
  case deleteLecture(userID: Int, timetableID: Int, lectureID: Int)
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
    case .deleteTable(let userID, let timetableID):
      "/api/users/\(userID)/timetables/\(timetableID)"
    case .addLecture(let userID, let timetableID, _):
      "/api/users/\(userID)/timetables/\(timetableID)/add-lecture"
    case .deleteLecture(let userID, let timetableID, _):
      "/api/users/\(userID)/timetables/\(timetableID)/remove-lecture"
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
    case .createTable, .addLecture, .deleteLecture:
        .post
    case .deleteTable:
        .delete
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
    case .addLecture(_, _, let lectureID):
        .requestParameters(parameters: ["lecture": lectureID], encoding: JSONEncoding.default)
    case .deleteLecture(_, _, let lectureID):
        .requestParameters(parameters: ["lecture": lectureID], encoding: JSONEncoding.default)
    case .fetchSemesters, .fetchCurrentSemester, .deleteTable:
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
