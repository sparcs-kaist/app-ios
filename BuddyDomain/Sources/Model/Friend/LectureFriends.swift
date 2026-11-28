//
//  LectureFriends.swift
//  BuddyDomain
//

import Foundation

/// Friends who share a lecture with the user, from their shared timetable or their
/// enrolled lectures.
public struct LectureFriends: Equatable, Sendable {
  /// A friend, and the semester of theirs to open to see the lecture.
  public struct Entry: Identifiable, Equatable, Sendable {
    public let friend: Friend
    public let term: FriendTimetableTerm

    public var id: Int { friend.id }

    public init(friend: Friend, term: FriendTimetableTerm) {
      self.friend = friend
      self.term = term
    }
  }

  /// Friends taking this very lecture, the same section.
  public let sameLecture: [Entry]
  /// Friends who took the same course in another semester.
  public let sameCourse: [Entry]

  public var isEmpty: Bool { sameLecture.isEmpty && sameCourse.isEmpty }

  public init(sameLecture: [Entry], sameCourse: [Entry]) {
    self.sameLecture = sameLecture
    self.sameCourse = sameCourse
  }
}
