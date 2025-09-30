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

@MainActor
@Observable
class LectureSearchViewModel {
  // MARK: - Properties
  enum ViewState: Equatable {
    case loaded
    case error(message: String)
  }
  var state: ViewState = .loaded
  var lectures: [Lecture] = []
  var searchKeyword: String = "" {
    didSet { searchKeywordSubject.send(searchKeyword) }
  }
  @ObservationIgnored private var cancellables = Set<AnyCancellable>()
  @ObservationIgnored private let searchKeywordSubject = PassthroughSubject<String, Never>()

  let itemsPerPage: Int = 50
  var currentPage: Int = 0

  // MARK: - Dependencies
  @ObservationIgnored @Injected(
    \.otlLectureRepository
  ) private var otlLectureRepository: OTLLectureRepositoryProtocol
  @ObservationIgnored @Injected(
    \.timetableUseCase
  ) private var timetableUseCase: TimetableUseCaseProtocol

  var isLastPage: Bool {
    return currentPage * itemsPerPage > lectures.count
  }

  func bind() {
    cancellables.removeAll()

    let searchPublisher = searchKeywordSubject
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .removeDuplicates()

    searchPublisher
      .debounce(for: .milliseconds(350), scheduler: DispatchQueue.main)
      .sink { [weak self] _ in
        guard let self else { return }
        Task {
          self.lectures.removeAll()
          self.state = .loaded
          self.currentPage = 0
          await fetchLectures()
        }
      }
      .store(in: &cancellables)
  }

  func fetchLectures() async {
    guard !isLastPage,
          let selectedSemester = timetableUseCase.selectedSemester else { return }

    do {
      let request = LectureSearchRequest(
        semester: selectedSemester,
        keyword: searchKeyword,
        limit: itemsPerPage,
        offset: currentPage * itemsPerPage
      )
      let page: [Lecture] = try await otlLectureRepository.searchLectures(request: request)

      self.lectures.append(contentsOf: page)
      self.currentPage += 1
    } catch {
      logger.error(error)
      state = .error(message: error.localizedDescription)
    }
  }
}
