//
//  OTLTimetableRepository.swift
//  soap
//
//  Created by Soongyu Kwon on 29/09/2025.
//

import Foundation
import BuddyDomain

@preconcurrency
import Moya

protocol OTLTimetableRepositoryProtocol: Sendable {
  func getTables(userID: Int, year: Int, semester: SemesterType) async throws -> [Timetable]
  func createTable(userID: Int, year: Int, semester: SemesterType) async throws -> Timetable
  func deleteTable(userID: Int, timetableID: Int) async throws
  func addLecture(userID: Int, timetableID: Int, lectureID: Int) async throws -> Timetable
  func deleteLecture(userID: Int, timetableID: Int, lectureID: Int) async throws -> Timetable
  func getSemesters() async throws -> [Semester]
  func getCurrentSemester() async throws -> Semester
}

final class OTLTimetableRepository: OTLTimetableRepositoryProtocol, Sendable {
  private let provider: MoyaProvider<OTLTimetableTarget>

  init(provider: MoyaProvider<OTLTimetableTarget>) {
    self.provider = provider
  }

  func getTables(userID: Int, year: Int, semester: SemesterType) async throws -> [Timetable] {
    let response = try await self.provider.request(.fetchTables(userID: userID, year: year, semester: semester.intValue))
    let result = try response.map([TimetableDTO].self).compactMap { $0.toModel() }

    return result
  }

  func createTable(userID: Int, year: Int, semester: SemesterType) async throws -> Timetable {
    let response = try await self.provider.request(
      .createTable(userID: userID, year: year, semester: semester.intValue)
    )
    let result = try response.map(TimetableDTO.self).toModel()

    return result
  }

  func deleteTable(userID: Int, timetableID: Int) async throws {
    let response = try await self.provider.request(
      .deleteTable(userID: userID, timetableID: timetableID)
    )
    _ = try response.filterSuccessfulStatusCodes()
  }

  func addLecture(userID: Int, timetableID: Int, lectureID: Int) async throws -> Timetable {
    let response = try await self.provider.request(
      .addLecture(userID: userID, timetableID: timetableID, lectureID: lectureID)
    )
    let result = try response.map(TimetableDTO.self).toModel()

    return result
  }

  func deleteLecture(userID: Int, timetableID: Int, lectureID: Int) async throws -> Timetable {
    let response = try await self.provider.request(
      .deleteLecture(userID: userID, timetableID: timetableID, lectureID: lectureID)
    )
    let result = try response.map(TimetableDTO.self).toModel()

    return result
  }

  func getSemesters() async throws -> [Semester] {
    let response = try await self.provider.request(.fetchSemesters)
    let result = try response.map([SemesterDTO].self).compactMap { $0.toModel() }

    return result
  }

  func getCurrentSemester() async throws -> Semester {
    let response = try await self.provider.request(.fetchCurrentSemester)
    let result = try response.map(SemesterDTO.self).toModel()

    return result
  }
}
