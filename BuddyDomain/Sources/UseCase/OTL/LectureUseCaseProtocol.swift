//
//  LectureUseCaseProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 07/03/2026.
//

import Foundation

public protocol LectureUseCaseProtocol: Sendable {
  func searchLecture(request: LectureSearchRequest) async throws -> [CourseLecture]
  func fetchDepartmentOptions() async throws -> [DepartmentOption]
  /// Fetches a user's taken lectures. Pass the numeric ID from `OTLUser.id`.
  func fetchUserLectureHistory(userID: Int) async throws -> OTLUserLectureHistory
}
