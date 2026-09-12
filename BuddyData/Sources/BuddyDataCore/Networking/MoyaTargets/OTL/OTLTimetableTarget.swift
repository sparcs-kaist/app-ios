//
//  OTLTimetableTarget.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 24/02/2026.
//

import Foundation
import Moya
import BuddyDomain

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
  case fetchActivities(timetableID: Int)
  case createActivity(timetableID: Int, draft: TimetableActivityDraft)
  case updateActivity(timetableID: Int, activityID: Int, draft: TimetableActivityDraft)
  case deleteActivity(timetableID: Int, activityID: Int)
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
    case .fetchActivities(let id), .createActivity(let id, _):
      "/api/v2/timetables/\(id)/custom-blocks"
    case .updateActivity(let id, let activityID, _), .deleteActivity(let id, let activityID):
      "/api/v2/timetables/\(id)/custom-blocks/\(activityID)"
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
         .fetchActivities,
         .fetchMyTable,
         .fetchSemesters,
         .fetchCurrentSemester:
        .get
    case .createTable, .createActivity:
        .post
    case .renameTable, .addLecture, .deleteLecture, .updateActivity:
        .patch
    case .deleteTable, .deleteActivity:
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
    case .createActivity(_, let draft), .updateActivity(_, _, let draft):
        .requestParameters(parameters: [
          "block_name": draft.title,
          "place": draft.location,
          "day": draft.day.rawValue,
          "begin": draft.begin,
          "end": draft.end
        ], encoding: JSONEncoding.default)
    case .fetchTablesBySemester, .fetchTable, .fetchSemesters, .fetchCurrentSemester, .fetchActivities, .deleteActivity:
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
