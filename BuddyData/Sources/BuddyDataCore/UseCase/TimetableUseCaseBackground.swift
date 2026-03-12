//
//  TimetableUseCaseBackground.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 09/10/2025.
//

import Foundation
import BuddyDomain

public final actor TimetableUseCaseBackground: TimetableUseCaseBackgroundProtocol {
  // MARK: - Dependencies
  private let otlTimetableRepository: OTLTimetableRepositoryProtocol

  public init(
    otlTimetableRepository: OTLTimetableRepositoryProtocol
  ) {
    self.otlTimetableRepository = otlTimetableRepository
  }

  public func getCurrentMyTable() async -> Timetable {
    do {
      let currentSemester = try await otlTimetableRepository.getCurrentSemester()
      let myTable = try await otlTimetableRepository.getMyTable(
        year: currentSemester.year,
        semester: currentSemester.semesterType
      )

      return myTable
    } catch {
      return Timetable(id: "-myTable", lectures: [])
    }
  }
}
