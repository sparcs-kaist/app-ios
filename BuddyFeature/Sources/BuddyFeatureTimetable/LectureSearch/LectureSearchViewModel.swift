//
//  LectureSearchViewModel.swift
//  soap
//
//  Created by Soongyu Kwon on 30/09/2025.
//

import SwiftUI
import Observation
import Combine
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
    didSet { searchKeywordSubject.send(searchKeyword) }
  }

  @ObservationIgnored private var cancellables = Set<AnyCancellable>()
  @ObservationIgnored private let searchKeywordSubject = PassthroughSubject<String, Never>()

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
    cancellables.removeAll()

    let searchPublisher = searchKeywordSubject
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .removeDuplicates()

    searchPublisher
      .debounce(for: .milliseconds(350), scheduler: DispatchQueue.main)
      .sink { [weak self] _ in
        guard let self else { return }
        guard !searchKeyword.isEmpty else {
          self.state = .loading
          self.courses.removeAll()
          return
        }

        Task {
          await fetchLectures(selectedSemester: selectedSemester)
        }
      }
      .store(in: &cancellables)
  }

  func fetchLectures(selectedSemester: Semester) async {
    guard let lectureUseCase else { return }
    guard !searchKeyword.isEmpty else { return }

    do {
      let request = LectureSearchRequest(
        year: selectedSemester.year,
        semester: selectedSemester.semesterType.intValue,
        department: [],
        level: [],
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
