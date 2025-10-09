//
//  TimetableUseCaseBackgroundProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 09/10/2025.
//

import Foundation

public protocol TimetableUseCaseBackgroundProtocol {
  var semesters: [Semester] { get async }
  var currentSemester: Semester? { get async }

  func load() async throws
  func getMyTable(for semester: Semester.ID) async -> Timetable
}
