//
//  CourseViewModel.swift
//  soap
//
//  Created by 하정우 on 10/1/25.
//

import Foundation
import Factory
import SwiftyBeaver

@MainActor
@Observable
class CourseViewModel {
  enum ViewState: Equatable {
    case loading
    case loaded
    case error(message: String)
  }
  
  // MARK: - Dependencies
  @ObservationIgnored @Injected(\.otlCourseRepository) private var otlCourseRepository: OTLCourseRepositoryProtocol
  @ObservationIgnored @Injected(\.foundationModelsUseCase) private var foundationModelsUseCase: FoundationModelsUseCaseProtocol
  
  // MARK: - Properties
  var reviews: [CourseReview] = []
  var state: ViewState = .loading
  
  // MARK: - Functions
  func fetchReviews(courseId: Int) async {
    do {
      self.state = .loading
      self.reviews = try await otlCourseRepository.getCourseReview(courseId: courseId, offset: 0, limit: 100)
      self.state = .loaded
    } catch {
      logger.error(error)
      self.state = .error(message: error.localizedDescription)
    }
  }
  
  var foundationModelsAvailable: Bool {
    foundationModelsUseCase.isAvailable
  }
  
  func summarise(_ text: String) async -> String {
    await foundationModelsUseCase.summarise(text, maxWords: 50, tone: "concise")
  }
  
  func likeReview(reviewId: Int) async throws {
    try await otlCourseRepository.likeReview(reviewId: reviewId)
  }
  
  func unlikeReview(reviewId: Int) async throws {
    try await otlCourseRepository.unlikeReview(reviewId: reviewId)
  }
}
