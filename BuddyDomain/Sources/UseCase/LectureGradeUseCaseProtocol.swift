//
//  LectureGradeUseCaseProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 25/09/2026.
//

import Foundation

/// Grades the user entered for their lectures, stored only on this device.
///
/// Grades belong to an OTL user (`OTLUser.id`) and are kept across sign-out, so
/// signing back in restores them and another account on the device never sees them.
public protocol LectureGradeUseCaseProtocol: Sendable {
  /// Every grade stored for `userID`, keyed by lecture ID.
  func grades(userID: Int) async throws -> [Int: LectureGrade]
  /// Stores a lecture's grade for `userID`, or removes it when `grade` is `nil`.
  func setGrade(_ grade: LectureGrade?, lectureID: Int, userID: Int) async throws
}
