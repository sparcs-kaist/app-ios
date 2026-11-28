//
//  TimetableSharingUseCaseProtocol.swift
//  BuddyDomain
//

import Foundation

/// Chooses, for each semester, the timetable every one of the user's friends sees.
public protocol TimetableSharingUseCaseProtocol: Sendable {
  /// The semesters worth choosing for: those with the user's timetables or enrolled lectures.
  func fetchSharableTerms() async throws -> Set<FriendTimetableTerm>
  func fetchSharing(semester: Semester) async throws -> TimetableSharing
  /// Shares `timetableID` for `semester`, or the user's enrolled lectures when it's `nil`.
  func share(timetableID: Int?, semester: Semester) async throws
}
