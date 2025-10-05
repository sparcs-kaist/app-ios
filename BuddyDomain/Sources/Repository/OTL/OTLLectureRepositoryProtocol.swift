//
//  OTLLectureRepositoryProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 05/10/2025.
//

import Foundation

public protocol OTLLectureRepositoryProtocol: Sendable {
  func searchLectures(request: LectureSearchRequest) async throws -> [Lecture]
  func fetchLectures(lectureID: Int) async throws -> [LectureReview]
  func writeReview(lectureID: Int, content: String, grade: Int, load: Int, speech: Int) async throws -> LectureReview
}
