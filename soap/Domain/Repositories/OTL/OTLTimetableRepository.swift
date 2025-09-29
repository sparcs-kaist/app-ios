//
//  OTLTimetableRepository.swift
//  soap
//
//  Created by Soongyu Kwon on 29/09/2025.
//

import Foundation

@preconcurrency
import Moya

protocol OTLTimetableRepositoryProtocol: Sendable {
  func getTables(userID: Int, year: Int, semester: SemesterType) async throws -> [Timetable]
  func createTable(userID: Int, year: Int, semester: SemesterType) async throws -> Timetable
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
}
