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
  /// Lectures and activities together, as the web reads a timetable.
  case fetchTable(timetableID: Int)
  case fetchMyTable(year: Int, semester: Int)
  case createTable(year: Int, semester: Int)
  case deleteTable(timetableID: Int)
  case renameTable(timetableID: Int, title: String)
  /// Lecture and activity changes, applied all together or not at all.
  case updateItems(timetableID: Int, changes: [TimetableItemChange])
  case fetchSemesters
  case fetchCurrentSemester
  /// Shares `timetableID` with every friend, or the enrolled lectures when it's `nil`.
  case setSharedTimetable(year: Int, semester: Int, timetableID: Int?)
  /// The semesters the user shares a timetable or enrolled lectures in.
  case fetchSharedSemesters
  /// What the user's friends see for a semester.
  case fetchSharedTimetable(year: Int, semester: Int)
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
      "/api/v2/timetables/\(timetableID)/items"
    case .fetchMyTable:
      "/api/v2/timetables/my-timetable"
    case .updateItems(let id, _):
      "/api/v2/timetables/\(id)/items"
    case .fetchSemesters:
      "/api/v2/semesters"
    case .fetchCurrentSemester:
      "/api/v2/semesters/current"
    case .setSharedTimetable, .fetchSharedTimetable:
      "/api/v2/timetables/shared"
    case .fetchSharedSemesters:
      "/api/v2/timetables/shared/semesters"
    }
  }

  public var method: Moya.Method {
    switch self {
    case .fetchTables,
         .fetchTablesBySemester,
         .fetchTable,
         .fetchMyTable,
         .fetchSemesters,
         .fetchCurrentSemester,
         .fetchSharedSemesters,
         .fetchSharedTimetable:
        .get
    case .createTable:
        .post
    case .renameTable, .updateItems, .setSharedTimetable:
        .patch
    case .deleteTable:
        .delete
    }
  }

  public var task: Moya.Task {
    switch self {
    case .fetchTables(let year, let semester), .fetchMyTable(let year, let semester),
         .fetchSharedTimetable(let year, let semester):
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
        .requestParameters(parameters: Self.parameters(for: changes), encoding: JSONEncoding.default)
    case .setSharedTimetable(let year, let semester, let timetableID):
        // `null` is how the server is told to share the enrolled lectures.
        .requestParameters(parameters: [
          "year": year,
          "semester": semester,
          "timetableId": timetableID.map { $0 as Any } ?? NSNull()
        ], encoding: JSONEncoding.default)
    case .fetchTablesBySemester, .fetchTable, .fetchSemesters, .fetchCurrentSemester, .fetchSharedSemesters:
        .requestPlain
    }
  }

  /// The grouped body the web sends. The server applies deletes, then updates,
  /// then adds, all at once; every group must be present, even when empty.
  private static func parameters(for changes: [TimetableItemChange]) -> [String: Any] {
    var addLectureIDs: [Int] = []
    var addBlocks: [[String: Any]] = []
    var deleteLectureIDs: [Int] = []
    var deleteBlockIDs: [Int] = []
    var updateBlocks: [[String: Any]] = []

    for change in changes {
      switch change {
      case .addLecture(let lectureID): addLectureIDs.append(lectureID)
      case .removeLecture(let lectureID): deleteLectureIDs.append(lectureID)
      case .addActivity(let draft): addBlocks.append(parameters(for: draft))
      case .updateActivity(let activityID, let draft):
        updateBlocks.append(parameters(for: draft).merging(["id": activityID]) { $1 })
      case .removeActivity(let activityID): deleteBlockIDs.append(activityID)
      }
    }

    return [
      "adds": ["lectureIds": addLectureIDs, "customBlocks": addBlocks],
      "deletes": ["lectureIds": deleteLectureIDs, "customBlockIds": deleteBlockIDs],
      "updates": ["customBlocks": updateBlocks]
    ]
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
