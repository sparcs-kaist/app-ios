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
  var reviews: [V2LectureReview] = []

  // MARK: - Dependencies
  @ObservationIgnored @Injected(
    \.v2ReviewUseCase
  ) private var reviewUseCase: V2ReviewUseCaseProtocol?

  // MARK: - Functions

  func fetchReviews(lecture: V2Lecture) async {
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
