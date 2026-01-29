//
//  CourseViewModel.swift
//  soap
//
//  Created by 하정우 on 10/1/25.
//

import Foundation
import Factory
import BuddyDomain

@MainActor
@Observable
public class CourseViewModel {
  public enum ViewState: Equatable {
    case loading
    case loaded
    case error(message: String)
  }
  
  // MARK: - Dependencies
  @ObservationIgnored @Injected(\.otlCourseRepository) private var otlCourseRepository: OTLCourseRepositoryProtocol?

  // MARK: - Properties
  public var reviews: [LectureReview] = []
  public var state: ViewState = .loading

  public init() { }

  // MARK: - Functions
  public func fetchReviews(courseId: Int) async {
    guard let otlCourseRepository else { return }
    do {
      self.state = .loading
      self.reviews = try await otlCourseRepository.fetchReviews(courseId: courseId, offset: 0, limit: 100)
      self.state = .loaded
    } catch {
      self.state = .error(message: error.localizedDescription)
    }
  }
}
