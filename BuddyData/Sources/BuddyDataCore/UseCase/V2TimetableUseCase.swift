//
//  V2TimetableUseCase.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 28/02/2026.
//

import Foundation
import Observation
import BuddyDomain

@Observable
public final class V2TimetableUseCase: V2TimetableUseCaseProtocol, @unchecked Sendable {
  // MARK: - Properties
  public var semesters: [Semester] = []
  public var selectedSemesterID: Semester.ID? = nil

  // MARK: - Dependencies
  private let otlTimetableRepository: OTLV2TimetableRepositoryProtocol
  private let sessionBirdgeService: SessionBridgeServiceProtocol?

  // MARK: - Initialiser
  public init(
    otlTimetableRepository: OTLV2TimetableRepositoryProtocol,
    sessionBirdgeService: SessionBridgeServiceProtocol?
  ) {
    self.otlTimetableRepository = otlTimetableRepository
    self.sessionBirdgeService = sessionBirdgeService
  }

  // MARK: - Computed
  public var selectedSemester: Semester? {
    guard let id = selectedSemesterID else { return nil }
    return semesters.first(where: { $0.id == id })
  }

  // MARK: - Functions
  public func getSemesters() async throws -> [Semester] {
    return try await otlTimetableRepository.getSemesters()
  }

  public func getCurrentSemesters() async throws -> Semester {
    return try await otlTimetableRepository.getCurrentSemester()
  }

  public func getTimetableList(semester: Semester) async throws -> [V2TimetableSummary] {
    return try await otlTimetableRepository
      .getTables(year: semester.year, semester: semester.semesterType)
  }
}
