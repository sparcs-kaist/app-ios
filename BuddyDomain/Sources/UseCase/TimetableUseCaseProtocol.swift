//
//  TimetableUseCaseProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 05/10/2025.
//

import Foundation

public protocol TimetableUseCaseProtocol: Observable, Sendable {
  var semesters: [Semester] { get }

  var selectedSemesterID: Semester.ID? { get set }
  var selectedTimetableID: Timetable.ID? { get set }

  var selectedSemester: Semester? { get }
  var selectedTimetable: Timetable? { get }

  var timetableIDsForSelectedSemester: [String] { get }
  var selectedTimetableDisplayName: String { get }

  var isEditable: Bool { get }

  func load() async throws
  func selectSemester(_ id: Semester.ID) async
  func createTable() async throws
  func deleteTable() async throws
  func addLecture(lecture: Lecture) async throws
  func deleteLecture(lecture: Lecture) async throws
}
