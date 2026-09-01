//
//  LectureSearchViewModel.swift
//  soap
//
//  Created by Soongyu Kwon on 30/09/2025.
//

import SwiftUI
import Observation
import Factory
import BuddyDomain

@MainActor
@Observable
class LectureSearchViewModel {
  // MARK: - Properties
  enum ViewState: Equatable {
    case loading
    case loaded
    case error(message: String)
  }

  var state: ViewState = .loading
  var courses: [CourseLecture] = []
  var searchKeyword: String = "" {
    didSet { scheduleSearch() }
  }

  @ObservationIgnored private var searchTask: Task<Void, Never>?
  @ObservationIgnored private var lastSearchKeyword: String?
  @ObservationIgnored private var selectedSemester: Semester?

  // MARK: - Dependencies
  @ObservationIgnored @Injected(
    \.v2LectureUseCase
  ) private var lectureUseCase: LectureUseCaseProtocol?
  @ObservationIgnored @Injected(
    \.crashlyticsService
  ) private var crashlyticsService: CrashlyticsServiceProtocol?
  @ObservationIgnored @Injected(
    \.analyticsService
  ) private var analyticsService: AnalyticsServiceProtocol?

  func bind(selectedSemester: Semester) {
    self.selectedSemester = selectedSemester
    searchTask?.cancel()
    lastSearchKeyword = nil
  }

  private func scheduleSearch() {
    let keyword = searchKeyword.trimmingCharacters(in: .whitespacesAndNewlines)
    guard keyword != lastSearchKeyword else { return }
    lastSearchKeyword = keyword

    searchTask?.cancel()
    searchTask = Task { [weak self] in
      try? await Task.sleep(for: .milliseconds(350))
      guard !Task.isCancelled, let self else { return }
      guard !self.searchKeyword.isEmpty else {
        self.state = .loading
        self.courses.removeAll()
        return
      }
      guard let selectedSemester = self.selectedSemester else { return }
      await self.fetchLectures(selectedSemester: selectedSemester)
    }
  }

  func fetchLectures(selectedSemester: Semester) async {
    guard let lectureUseCase else { return }
    guard !searchKeyword.isEmpty else { return }

    do {
      let request = LectureSearchRequest(
        semester: selectedSemester,
        keyword: searchKeyword,
        limit: 100,
        offset: 0
      )
      let page: [CourseLecture] = try await lectureUseCase.searchLecture(request: request)
      self.courses = page
      self.state = .loaded
      analyticsService?.logEvent(LectureSearchViewEvent.lecturesSearched)
    } catch {
      crashlyticsService?.recordException(error: error)
      state = .error(message: error.localizedDescription)
    }
  }
}
