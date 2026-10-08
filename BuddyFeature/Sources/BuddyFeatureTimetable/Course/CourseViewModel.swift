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
  /// The professor whose offerings and reviews are highlighted; `nil` shows everyone.
  public private(set) var selectedProfessorID: Int? = nil

  @ObservationIgnored private var reviewTask: Task<Void, Never>?

  public init() { }

  /// Everyone who has taught the course, by name.
  public var professors: [Professor] {
    var seen = Set<Int>()
    return (course?.history ?? [])
      .flatMap { $0.classes.flatMap(\.professors) }
      .filter { seen.insert($0.id).inserted }
      .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
  }

  public var selectedProfessor: Professor? {
    professors.first { $0.id == selectedProfessorID }
  }

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

  /// Narrows the reviews to one professor, refetching them from the server.
  public func selectProfessor(id: Int?) {
    guard id != selectedProfessorID, let courseID = course?.id else { return }
    selectedProfessorID = id
    analyticsService?.logEvent(CourseViewEvent.professorSelected)
    reviewTask?.cancel()
    reviewTask = Task { await fetchReviews(courseID: courseID) }
  }

  public func fetchReviews(courseID: Int) async {
    guard let reviewUseCase else { return }
    let professorID = selectedProfessorID
    do {
      self.state = .loading
      let page = try await reviewUseCase.fetchReviews(courseID: courseID, professorID: professorID, offset: 0, limit: 100)
      // Drop a response that a newer professor selection has superseded.
      guard !Task.isCancelled, professorID == selectedProfessorID else { return }
      self.reviewPage = page
      self.reviews = page.reviews
      self.state = .loaded
      analyticsService?.logEvent(CourseViewEvent.reviewsLoaded)
    } catch {
      guard !Task.isCancelled, professorID == selectedProfessorID else { return }
      crashlyticsService?.recordException(error: error)
      self.state = .error(message: error.localizedDescription)
    }
  }
}
