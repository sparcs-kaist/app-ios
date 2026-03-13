//
//  ReviewUseCaseProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 07/03/2026.
//

import Foundation

public protocol ReviewUseCaseProtocol: Sendable {
  func fetchReviews(courseID: Int, professorID: Int?, offset: Int, limit: Int) async throws -> LectureReviewPage
  func writeReview(lectureID: Int, content: String, grade: Int, load: Int, speech: Int) async throws
  func likeReview(reviewID: Int) async throws
  func unlikeReview(reviewID: Int) async throws
}
