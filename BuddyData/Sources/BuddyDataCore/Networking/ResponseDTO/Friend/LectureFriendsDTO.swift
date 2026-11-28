//
//  LectureFriendsDTO.swift
//  BuddyData
//

import Foundation
import BuddyDomain

/// `GET /api/v2/friends/lectures/{lectureId}/overlaps`
struct LectureFriendsDTO: Decodable {
  struct Entry: Decodable {
    struct Timetable: Decodable {
      /// `null` for the friend's enrolled lectures.
      let id: Int?
      let year: Int
      let semester: Int
    }

    let id: Int
    let name: String
    let isFavorite: Bool
    let timetable: Timetable

    func toModel() -> LectureFriends.Entry {
      LectureFriends.Entry(
        // This endpoint doesn't say whether the friend is in class now.
        friend: Friend(id: id, name: name, isFavorite: isFavorite, hasScheduleNow: nil),
        term: FriendTimetableTerm(year: timetable.year, semester: .fromRawValue(timetable.semester))
      )
    }
  }

  let sameLecture: [Entry]
  let sameCourseOtherSemester: [Entry]

  func toModel() -> LectureFriends {
    LectureFriends(
      sameLecture: sameLecture.map { $0.toModel() },
      sameCourse: sameCourseOtherSemester.map { $0.toModel() }
    )
  }
}
