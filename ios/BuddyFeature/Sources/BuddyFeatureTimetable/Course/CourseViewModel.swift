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
  @ObservationIgnored @Injected(
    \.v2CourseUseCase
  ) private var courseUseCase: CourseUseCaseProtocol?
  @ObservationIgnored @Injected(\.v2ReviewUseCase) private var reviewUseCase: ReviewUseCaseProtocol?
  @ObservationIgnored @Injected(
    \.crashlyticsService
  ) private var crashlyticsService: CrashlyticsServiceProtocol?
  @ObservationIgnored @Injected(
    \.analyticsService
  ) private var analyticsService: AnalyticsServiceProtocol?

  // MARK: - Properties
  public var course: Course? = nil
  public var reviews: [LectureReview] = []
  public var state: ViewState = .loading
  public var reviewPage: LectureReviewPage? = nil

  public init() { }

  // MARK: - Functions

  public func setup(courseID: Int) async {
    guard let courseUseCase else { return }
    do {
      self.course = try await courseUseCase.getCourse(courseID: courseID)
      analyticsService?.logEvent(CourseViewEvent.courseLoaded)
      await fetchReviews(courseID: courseID)
    } catch {
      crashlyticsService?.recordException(error: error)
      self.state = .error(message: error.localizedDescription)
    }
  }

  public func fetchReviews(courseID: Int) async {
    guard let reviewUseCase else { return }
    do {
      self.state = .loading
      let page = try await reviewUseCase.fetchReviews(courseID: courseID, professorID: nil, offset: 0, limit: 100)
      self.reviewPage = page
      self.reviews = page.reviews
      self.state = .loaded
      analyticsService?.logEvent(CourseViewEvent.reviewsLoaded)
    } catch {
      crashlyticsService?.recordException(error: error)
      self.state = .error(message: error.localizedDescription)
    }
  }
}
