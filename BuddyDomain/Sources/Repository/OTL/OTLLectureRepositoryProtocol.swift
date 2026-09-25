//
//  OTLLectureRepositoryProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 07/03/2026.
//

import Foundation

public protocol OTLLectureRepositoryProtocol: Sendable {
  func searchLecture(request: LectureSearchRequest) async throws -> [CourseLecture]
  /// Fetches a user's taken lectures using the numeric OTL user ID.
  func fetchUserLectureHistory(userID: Int) async throws -> OTLUserLectureHistory
}
