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
  private let userUseCase: UserUseCaseProtocol
  private let otlTimetableRepository: OTLTimetableRepositoryProtocol

  public init(
    userUseCase: UserUseCaseProtocol,
    otlTimetableRepository: OTLTimetableRepositoryProtocol
  ) {
    self.userUseCase = userUseCase
    self.otlTimetableRepository = otlTimetableRepository
  }

  public func load() async throws {
    guard store.isEmpty || semesters.isEmpty else { return }

    async let fetchSemesters = otlTimetableRepository.getSemesters()
    async let fetchCurrentSemester = otlTimetableRepository.getCurrentSemester()

    let (fetchedSemesters, fetchedCurrentSemester) = try await (
      fetchSemesters,
      fetchCurrentSemester
    )

    self.semesters = fetchedSemesters
    self.currentSemester = fetchedCurrentSemester

    let user: OTLUser? = await userUseCase.otlUser
    self.store = Dictionary(uniqueKeysWithValues: semesters.map { semester in
      (semester.id, [makeMyTable(for: semester, user: user)])
    })
  }

  public func getMyTable(for semester: Semester.ID) -> Timetable {
    if let existing = store[semester]?.first {
      return existing
    }

    // return emtpy timetable
    return Timetable(id: "\(semester)-myTable", lectures: [])
  }
  
  /// Creates the local "My Table" for a semester using user's lectures.
  private func makeMyTable(for semester: Semester, user: OTLUser?) -> Timetable {
    let lectures = user?.myTimetableLectures.filter {
      $0.year == semester.year && $0.semester == semester.semesterType
    } ?? []
    return Timetable(id: "\(semester.id)-myTable", lectures: lectures)
  }
}
