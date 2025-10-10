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

  // MARK: - Dependencies
  @ObservationIgnored @Injected(
    \.otlLectureRepository
  ) private var otlLectureRepository: OTLLectureRepositoryProtocol

  // MARK: - Functions

  func fetchReviews(lectureID: Int) async {
    do {
      self.reviews = try await otlLectureRepository.fetchLectures(lectureID: lectureID)
      self.state = .loaded
    } catch {
      self.state = .error(message: error.localizedDescription)
      logger.error(error)
    }
  }
}
