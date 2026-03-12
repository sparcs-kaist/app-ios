//
//  LectureDetailViewModel.swift
//  soap
//
//  Created by Soongyu Kwon on 02/10/2025.
//

import SwiftUI
import Observation
import Factory
import BuddyDomain

@MainActor
@Observable
class LectureDetailViewModel {
  enum ViewState: Equatable {
    case loading
    case loaded
    case error(message: String)
  }
  var state: ViewState = .loading
  var reviews: [LectureReview] = []
  var course: Course? = nil

  // MARK: - Dependencies
  @ObservationIgnored @Injected(
    \.v2ReviewUseCase
  ) private var reviewUseCase: ReviewUseCaseProtocol?
  @ObservationIgnored @Injected(
    \.v2CourseUseCase
  ) private var courseUseCase: CourseUseCaseProtocol?

  // MARK: - Functions

  func fetchCourse(courseID: Int) async {
    guard let courseUseCase else { return }

    do {
      self.course = try await courseUseCase.getCourse(courseID: courseID)
    } catch {
      self.state = .error(message: error.localizedDescription)
    }
  }

  func fetchReviews(lecture: Lecture) async {
    guard let reviewUseCase else { return }

    do {
      let page = try await reviewUseCase
        .fetchReviews(
          courseID: lecture.courseID,
          professorID: lecture.professors.first?.id,
          offset: 0,
          limit: 100
        )
      self.reviews = page.reviews
      self.state = .loaded
    } catch {
      self.state = .error(message: error.localizedDescription)
    }
  }
}
