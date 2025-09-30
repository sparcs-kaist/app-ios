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
    case loaded(reviews: [CourseReview])
    case error(message: String)
  }
  
  // MARK: - Dependencies
  @ObservationIgnored @Injected(\.otlCourseRepository) private var otlCourseRepository: OTLCourseRepositoryProtocol
  
  // MARK: - Properties
  var reviews: [CourseReview] = []
  var state: ViewState = .loading
  
  // MARK: - Functions
  func fetchReviews(courseId: Int) async {
    do {
      self.state = .loading
      self.reviews = try await otlCourseRepository.getCourseReview(courseId: courseId, offset: 0, limit: 100)
      self.state = .loaded(reviews: self.reviews)
    } catch {
      logger.error(error)
      self.state = .error(message: error.localizedDescription)
    }
  }
}
