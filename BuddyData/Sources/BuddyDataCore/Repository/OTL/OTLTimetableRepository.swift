//
//  OTLTimetableRepository.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 24/02/2026.
//

import Foundation
import BuddyDomain

@preconcurrency
import Moya

public final class OTLTimetableRepository: OTLTimetableRepositoryProtocol, Sendable {
  public let provider: MoyaProvider<OTLTimetableTarget>

  public init(provider: MoyaProvider<OTLTimetableTarget>) {
    self.provider = provider
  }

  public func getTables(year: Int, semester: SemesterType) async throws -> [TimetableSummary] {
    let response = try await self.provider.request(
      .fetchTables(year: year, semester: semester.intValue)
    )
    let result = try response.map(TimetableSummaryListDTO.self)

    return result.timetables.compactMap { $0.toModel() }
  }

  public func getSharing(year: Int, semester: SemesterType) async throws -> TimetableSharing {
    let response = try await provider.request(.fetchTables(year: year, semester: semester.intValue))
    return try response.map(TimetableSharingDTO.self).toModel()
  }

  public func getSharedSemesters() async throws -> [FriendTimetableTerm] {
    let response = try await provider.request(.fetchSharedSemesters)
    // Same shape as a friend's list of shared semesters.
    return try response.map(FriendSharedSemestersDTO.self).toModel()
  }

  public func setSharedTimetable(year: Int, semester: SemesterType, timetableID: Int?) async throws {
    _ = try await provider.request(
      .setSharedTimetable(year: year, semester: semester.intValue, timetableID: timetableID)
    )
  }

  public func getTable(timetableID: Int) async throws -> Timetable {
    let response = try await self.provider.request(.fetchTable(timetableID: timetableID))
    return try response.map(TimetableDTO.self).toModel(id: String(timetableID))
  }

  @discardableResult
  public func createActivity(timetableID: Int, draft: TimetableActivityDraft) async throws -> Timetable? {
    try await updateItems(timetableID: timetableID, changes: [.addActivity(draft)])
  }

  @discardableResult
  public func updateActivity(timetableID: Int, activityID: Int, draft: TimetableActivityDraft) async throws -> Timetable? {
    try await updateItems(timetableID: timetableID, changes: [.updateActivity(activityID: activityID, draft)])
  }

  @discardableResult
  public func deleteActivity(timetableID: Int, activityID: Int) async throws -> Timetable? {
    try await updateItems(timetableID: timetableID, changes: [.removeActivity(activityID: activityID)])
  }

  /// Every lecture and activity change goes through the batch endpoint, which
  /// checks overlaps against the server's own copy, times this client can't see
  /// included.
  @discardableResult
  public func updateItems(timetableID: Int, changes: [TimetableItemChange]) async throws -> Timetable? {
    let response: Response
    do {
      response = try await provider.request(.updateItems(timetableID: timetableID, changes: changes))
    } catch NetworkError.serverError(statusCode: 409) {
      throw TimetableActivityError.overlap
    }
    // The changes are applied by now, so an answer this client can't read is not a failure.
    return try? response.map(TimetableDTO.self).toModel(id: String(timetableID))
  }

  public func createTable(year: Int, semester: SemesterType) async throws -> TableCreation {
    let response = try await self.provider.request(
      .createTable(year: year, semester: semester.intValue)
    )
    return try response.map(TableCreationDTO.self).toModel()
  }

  public func getMyTable(year: Int, semester: SemesterType) async throws -> Timetable {
    let response = try await self.provider.request(
      .fetchMyTable(year: year, semester: semester.intValue)
    )
    return try response.map(TimetableDTO.self).toModel(id: "\(year)-\(semester.rawValue)-myTable")
  }
	
	public func getTableList() async throws -> [SemesterWithTimetables] {
		let response = try await self.provider.request(.fetchTablesBySemester)
		
		return try response.map(TimetableBySemesterListDTO.self).toModel().semesters
	}

  public func deleteTable(timetableID: Int) async throws {
    _ = try await self.provider.request(.deleteTable(timetableID: timetableID))
  }

  public func renameTable(timetableID: Int, title: String) async throws {
    _ = try await self.provider.request(.renameTable(timetableID: timetableID, title: title))
  }

  @discardableResult
  public func addLecture(timetableID: Int, lectureID: Int) async throws -> Timetable? {
    try await updateItems(timetableID: timetableID, changes: [.addLecture(lectureID: lectureID)])
  }

  @discardableResult
  public func deleteLecture(timetableID: Int, lectureID: Int) async throws -> Timetable? {
    try await updateItems(timetableID: timetableID, changes: [.removeLecture(lectureID: lectureID)])
  }

  public func getSemesters() async throws -> [Semester] {
    let response = try await self.provider.request(.fetchSemesters)
    return try response.map(SemesterListDTO.self).semesters.compactMap { $0.toModel() }
  }

  public func getCurrentSemester() async throws -> Semester {
    let response = try await self.provider.request(.fetchCurrentSemester)
    return try response.map(SemesterDTO.self).toModel()
  }
}
