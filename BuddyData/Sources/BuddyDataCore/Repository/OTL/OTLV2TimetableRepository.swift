//
//  OTLV2TimetableRepository.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 24/02/2026.
//

import Foundation
import BuddyDomain

@preconcurrency
import Moya

public final class OTLV2TimetableRepository: OTLV2TimetableRepositoryProtocol, Sendable {
  public let provider: MoyaProvider<OTLV2TimetableTarget>

  public init(provider: MoyaProvider<OTLV2TimetableTarget>) {
    self.provider = provider
  }

  public func getTables(year: Int, semester: SemesterType) async throws -> [V2TimetableSummary] {
    let response = try await self.provider.request(
      .fetchTables(year: year, semester: semester.intValue)
    )
    let result = try response.map(V2TimetableSummaryListDTO.self)

    return result.timetables.compactMap { $0.toModel() }
  }

  public func getMyTable(year: Int, semester: SemesterType) async throws -> V2Timetable {
    let response = try await self.provider.request(
      .fetchMyTable(year: year, semester: semester.intValue)
    )
    return try response.map(V2TimetableDTO.self).toModel()
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
    return try response.map(V2SemesterListDTO.self).semesters.compactMap { $0.toModel() }
  }

  public func getCurrentSemester() async throws -> Semester {
    let response = try await self.provider.request(.fetchCurrentSemester)
    return try response.map(SemesterDTO.self).toModel()
  }
}
