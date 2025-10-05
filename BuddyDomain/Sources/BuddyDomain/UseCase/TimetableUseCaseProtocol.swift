//
//  TimetableUseCaseProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 05/10/2025.
//

import Foundation

@MainActor
public protocol TimetableUseCaseProtocol: Observable {
  var semesters: [Semester] { get }

  var selectedSemesterID: Semester.ID? { get set }
  var selectedTimetableID: Timetable.ID? { get set }

  var selectedSemester: Semester? { get }
  var selectedTimetable: Timetable? { get }

  var timetableIDsForSelectedSemester: [String] { get }
  var selectedTimetableDisplayName: String { get }

  var isEditable: Bool { get }

  func load() async throws
  func createTable() async throws
  func deleteTable() async throws
  func addLecture(lecture: Lecture) async throws
  func deleteLecture(lecture: Lecture) async throws
}
