//
//  OTLCourseRepositoryProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 05/10/2025.
//

import Foundation

public protocol OTLCourseRepositoryProtocol: Sendable {
  func searchCourse(name: String, offset: Int, limit: Int) async throws -> [Course]
  func fetchReviews(courseId: Int, offset: Int, limit: Int) async throws -> [LectureReview]
  func likeReview(reviewId: Int) async throws
  func unlikeReview(reviewId: Int) async throws
}
