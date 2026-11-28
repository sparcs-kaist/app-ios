//
//  FriendTimetable.swift
//  BuddyDomain
//

import Foundation

/// A semester a friend has a timetable for: one they shared, or lectures they enrolled in.
public struct FriendTimetableTerm: Identifiable, Hashable, Sendable {
  public let year: Int
  public let semester: SemesterType

  public var id: String { "\(year)-\(semester.rawValue)" }
  public var description: String { "\(year) \(semester.description)" }

  public init(year: Int, semester: SemesterType) {
    self.year = year
    self.semester = semester
  }
}

/// What a friend shows their friends for one semester.
public struct FriendTimetable: Equatable, Sendable {
  public enum Source: Equatable, Sendable {
    /// A timetable the friend chose to share, by its name.
    case shared(name: String)
    /// The friend's enrolled lectures, shown when they haven't shared a timetable that semester.
    case enrolment
  }

  public let term: FriendTimetableTerm
  public let source: Source
  public let timetable: Timetable

  public init(term: FriendTimetableTerm, source: Source, timetable: Timetable) {
    self.term = term
    self.source = source
    self.timetable = timetable
  }
}
