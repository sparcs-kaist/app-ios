//
//  OTLCourseRepository.swift
//  soap
//
//  Created by 하정우 on 10/1/25.
//

import Foundation
import BuddyDomain

@preconcurrency
import Moya

final class OTLCourseRepository: OTLCourseRepositoryProtocol, Sendable {
  private let provider: MoyaProvider<OTLCourseTarget>
  
  init(provider: MoyaProvider<OTLCourseTarget>) {
    self.provider = provider
  }
  
  func searchCourse(name: String, offset: Int, limit: Int) async throws -> [Course] {
    let response = try await self.provider.request(
      .searchCourse(name: name, offset: offset, limit: limit)
    )
    let result = try response.map([CourseDTO].self).compactMap { $0.toModel() }
    
    return result
  }
  
  func fetchReviews(courseId: Int, offset: Int, limit: Int) async throws -> [LectureReview]{
    let response = try await self.provider.request(
      .fetchReviews(courseId: courseId, offset: offset, limit: limit)
    )
    let result = try response.map([LectureReviewDTO].self).compactMap { $0.toModel() }

    return result
  }
  
  func likeReview(reviewId: Int) async throws {
    _ = try await self.provider.request(.likeReview(reviewId: reviewId)).filterSuccessfulStatusCodes()
  }
  
  func unlikeReview(reviewId: Int) async throws {
    _ = try await self.provider.request(.unlikeReview(reviewId: reviewId)).filterSuccessfulStatusCodes()
  }
}
