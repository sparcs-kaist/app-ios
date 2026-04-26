//
//  OTLTimetableTarget.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 24/02/2026.
//

import Foundation
import Moya

public enum OTLTimetableTarget {
  case fetchTables(year: Int, semester: Int)
  case fetchTablesBySemester
  case fetchTable(timetableID: Int)
  case fetchMyTable(year: Int, semester: Int)
  case createTable(year: Int, semester: Int)
  case deleteTable(timetableID: Int)
  case renameTable(timetableID: Int, title: String)
  case addLecture(timetableID: Int, lectureID: Int)
  case deleteLecture(timetableID: Int, lectureID: Int)
  case fetchSemesters
  case fetchCurrentSemester
}

extension OTLTimetableTarget: TargetType, AccessTokenAuthorizable {
  public var baseURL: URL {
    BackendURL.otlBackendURL
  }

  public var path: String {
    switch self {
    case .fetchTables, .deleteTable, .renameTable, .createTable:
      "/api/v2/timetables"
    case .fetchTablesBySemester:
      "/api/v2/timetables/by-semester"
    case .fetchTable(let timetableID):
      "/api/v2/timetables/\(timetableID)"
    case .fetchMyTable:
      "/api/v2/timetables/my-timetable"
    case .addLecture(let timetableID, _), .deleteLecture(let timetableID, _):
      "/api/v2/timetables/\(timetableID)"
    case .fetchSemesters:
      "/api/v2/semesters"
    case .fetchCurrentSemester:
      "/api/v2/semesters/current"
    }
  }

  public var method: Moya.Method {
    switch self {
    case .fetchTables,
         .fetchTablesBySemester,
         .fetchTable,
         .fetchMyTable,
         .fetchSemesters,
         .fetchCurrentSemester:
        .get
    case .createTable:
        .post
    case .renameTable, .addLecture, .deleteLecture:
        .patch
    case .deleteTable:
        .delete
    }
  }

  public var task: Moya.Task {
    switch self {
    case .fetchTables(let year, let semester), .fetchMyTable(let year, let semester):
        .requestParameters(parameters: [
          "year": year,
          "semester": semester
        ], encoding: URLEncoding.default)
    case .addLecture(_, let lectureID):
        .requestParameters(parameters: [
          "action": "add",
          "lectureId": lectureID
        ], encoding: JSONEncoding.default)
    case .createTable(let year, let semester):
        .requestParameters(parameters: [
          "year": year,
          "semester": semester,
          "lectureIds": []
        ], encoding: JSONEncoding.default)
    case .deleteLecture(_, let lectureID):
        .requestParameters(parameters: [
          "action": "delete",
          "lectureId": lectureID
        ], encoding: JSONEncoding.default)
    case .deleteTable(let timetableID):
        .requestParameters(parameters: [
          "id": timetableID
        ], encoding: JSONEncoding.default)
    case .renameTable(let timetableID, let title):
        .requestParameters(parameters: [
          "id": timetableID,
          "name": title
        ], encoding: JSONEncoding.default)
    case .fetchTablesBySemester, .fetchTable, .fetchSemesters, .fetchCurrentSemester:
        .requestPlain
    }
  }

  public var headers: [String: String]? {
    [
      "Content-Type": "application/json",
      "Accept-Language": Bundle.main.preferredLocalizations.first ?? "ko"
    ]
  }

  public var authorizationType: Moya.AuthorizationType? {
		switch self {
		case .fetchCurrentSemester:
				.none
		default:
				.bearer
		}
  }
}
