//
//  FriendSharedTimetableDTO.swift
//  BuddyData
//

import Foundation
import BuddyDomain

/// `GET /api/v2/friends/{id}/timetables/shared/semesters`
struct FriendSharedSemestersDTO: Decodable {
  struct Term: Decodable {
    let year: Int
    let semester: Int
  }

  let semesters: [Term]

  /// Newest first, as the web lists them.
  func toModel() -> [FriendTimetableTerm] {
    semesters
      .map { FriendTimetableTerm(year: $0.year, semester: .fromRawValue($0.semester)) }
      .sorted { ($0.year, $0.semester.intValue) > ($1.year, $1.semester.intValue) }
  }
}

/// `GET /api/v2/friends/{id}/timetables/shared?year&semester`
struct FriendSharedTimetableDTO: Decodable {
  let lectures: [LectureDTO]
  let customBlocks: [TimetableActivityDTO]?
  /// `timetable` for a timetable the friend shared, `scholar` for their enrolled lectures.
  let timetableType: String
  let name: String

  func toModel(friendID: Int, term: FriendTimetableTerm) -> FriendTimetable {
    FriendTimetable(
      term: term,
      source: timetableType == "timetable" ? .shared(name: name) : .enrolment,
      timetable: Timetable(
        id: "friend-\(friendID)-\(term.id)",
        lectures: lectures.map { $0.toModel() },
        activities: (customBlocks ?? []).map { $0.toModel() }
      )
    )
  }
}
