//
//  TimetableUseCaseBackground.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 09/10/2025.
//

import Foundation
import BuddyDomain

public final actor TimetableUseCaseBackground: TimetableUseCaseBackgroundProtocol {
  private var store: [Semester.ID: [Timetable]] = [:]
  public var semesters: [Semester] = []
  public var currentSemester: Semester? = nil

  // MARK: - Dependencies
  private let otlTimetableRepository: OTLV2TimetableRepositoryProtocol

  public init(
    otlTimetableRepository: OTLV2TimetableRepositoryProtocol
  ) {
    self.otlTimetableRepository = otlTimetableRepository
  }

  public func getCurrentMyTable() async -> V2Timetable {
    do {
      let currentSemester = try await otlTimetableRepository.getCurrentSemester()
      let myTable = try await otlTimetableRepository.getMyTable(
        year: currentSemester.year,
        semester: currentSemester.semesterType
      )

      return myTable
    } catch {
      return V2Timetable(id: "-myTable", lectures: [])
    }
  }
}
