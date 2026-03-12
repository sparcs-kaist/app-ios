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

  public func getTable(timetableID: Int) async throws -> Timetable {
    let response = try await self.provider.request(.fetchTable(timetableID: timetableID))
    return try response.map(TimetableDTO.self).toModel(id: String(timetableID))
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

  public func deleteTable(timetableID: Int) async throws {
    _ = try await self.provider.request(.deleteTable(timetableID: timetableID))
  }

  public func renameTable(timetableID: Int, title: String) async throws {
    _ = try await self.provider.request(.renameTable(timetableID: timetableID, title: title))
  }

  public func addLecture(timetableID: Int, lectureID: Int) async throws {
    _ = try await self.provider.request(.addLecture(timetableID: timetableID, lectureID: lectureID))
  }

  public func deleteLecture(timetableID: Int, lectureID: Int) async throws {
    _ = try await self.provider
      .request(.deleteLecture(timetableID: timetableID, lectureID: lectureID))
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
