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
  case fetchActivities(timetableID: Int)
  /// Lecture and activity changes, applied all together or not at all.
  case updateItems(timetableID: Int, changes: [TimetableItemChange])
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
    case .fetchActivities(let id):
      "/api/v2/timetables/\(id)/custom-blocks"
    case .updateItems(let id, _):
      "/api/v2/timetables/\(id)/items"
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
    case .createTable:
        .post
    case .renameTable, .updateItems:
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
    case .createTable(let year, let semester):
        .requestParameters(parameters: [
          "year": year,
          "semester": semester,
          "lectureIds": []
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
    case .updateItems(_, let changes):
        .requestParameters(parameters: [
          "changes": changes.map(Self.parameters)
        ], encoding: JSONEncoding.default)
    case .fetchTablesBySemester, .fetchTable, .fetchSemesters, .fetchCurrentSemester, .fetchActivities:
        .requestPlain
    }
  }

  private static func parameters(for change: TimetableItemChange) -> [String: Any] {
    switch change {
    case .addLecture(let lectureID): ["op": "add", "kind": "lecture", "lectureId": lectureID]
    case .removeLecture(let lectureID): ["op": "remove", "kind": "lecture", "id": lectureID]
    case .addActivity(let draft): ["op": "add", "kind": "custom", "data": parameters(for: draft)]
    case .updateActivity(let activityID, let draft):
      ["op": "update", "kind": "custom", "id": activityID, "data": parameters(for: draft)]
    case .removeActivity(let activityID): ["op": "remove", "kind": "custom", "id": activityID]
    }
  }

  /// `times` carries every range and replaces the block's existing ones on
  /// update; the server derives the legacy day/begin/end from the first.
  private static func parameters(for draft: TimetableActivityDraft) -> [String: Any] {
    [
      "block_name": draft.title,
      "place": draft.location,
      "times": draft.times.map { ["day": $0.day.rawValue, "begin": $0.begin, "end": $0.end] }
    ]
  }

  public var headers: [String: String]? {
    var headers = [
      "Content-Type": "application/json",
      "Accept-Language": Bundle.main.preferredLocalizations.first ?? "ko"
    ]
    
    #if DEBUG
    if !OTLDebugSecrets.key.isEmpty {
      headers["X-SID-AUTH-TOKEN"] = OTLDebugSecrets.key
    }
    #endif
    
    return headers
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
