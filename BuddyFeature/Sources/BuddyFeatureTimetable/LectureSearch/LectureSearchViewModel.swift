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
  var lectures: [Lecture] = []
  var searchKeyword: String = "" {
    didSet { searchKeywordSubject.send(searchKeyword) }
  }
  @ObservationIgnored private var cancellables = Set<AnyCancellable>()
  @ObservationIgnored private let searchKeywordSubject = PassthroughSubject<String, Never>()

  // MARK: - Dependencies
  @ObservationIgnored @Injected(
    \.otlLectureRepository
  ) private var otlLectureRepository: OTLLectureRepositoryProtocol?
  @ObservationIgnored @Injected(
    \.timetableUseCase
  ) private var timetableUseCase: TimetableUseCaseProtocol?

  func bind() {
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
          self.lectures.removeAll()
          return
        }

        Task {
          await fetchLectures()
        }
      }
      .store(in: &cancellables)
  }

  func fetchLectures() async {
    guard let otlLectureRepository, let timetableUseCase else { return }
    guard let selectedSemester = timetableUseCase.selectedSemester,
          !searchKeyword.isEmpty else { return }

    do {
      let request = LectureSearchRequest(
        semester: selectedSemester,
        keyword: searchKeyword,
        limit: 100,
        offset: 0
      )
      let page: [Lecture] = try await otlLectureRepository.searchLectures(request: request)

      self.lectures = page
      self.state = .loaded
    } catch {
      state = .error(message: error.localizedDescription)
    }
  }
}
