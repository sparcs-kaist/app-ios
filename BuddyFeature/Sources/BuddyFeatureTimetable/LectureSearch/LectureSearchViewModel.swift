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
  var filter = LectureSearchFilter() {
    didSet { scheduleSearch() }
  }

  private(set) var departments: [DepartmentOption] = []
  /// The user's interested departments from Settings, listed first in the department picker.
  private(set) var interestedDepartmentIDs: Set<Int> = []
  private(set) var departmentState: ViewState = .loading
  /// Whether the server may hold more lectures for the current search.
  private(set) var canLoadMore: Bool = false

  /// A search runs as soon as there is a keyword, a filter, or both.
  var hasCriteria: Bool { !currentQuery.isEmpty }

  /// Lectures fetched so far. The API pages by lecture rather than by course, so this is the
  /// offset of the next page.
  var loadedLectureCount: Int { courses.lectureCount }

  /// Departments chosen in the filter, in the order the server lists them.
  var selectedDepartments: [DepartmentOption] {
    departments.filter { filter.departmentIDs.contains($0.id) }
  }

  private struct Query: Equatable {
    var keyword: String = ""
    var filter = LectureSearchFilter()

    var isEmpty: Bool { keyword.isEmpty && filter.isEmpty }
  }

  private static let pageSize = 100

  @ObservationIgnored private var searchTask: Task<Void, Never>?
  @ObservationIgnored private var lastQuery = Query()
  /// Bumped for every new search so a slow response cannot overwrite a newer one.
  @ObservationIgnored private var searchGeneration = 0
  @ObservationIgnored private var selectedSemester: Semester?

  private var currentQuery: Query {
    Query(keyword: searchKeyword.trimmingCharacters(in: .whitespacesAndNewlines), filter: filter)
  }

  // MARK: - Dependencies
  @ObservationIgnored @Injected(
    \.v2LectureUseCase
  ) private var lectureUseCase: LectureUseCaseProtocol?
  @ObservationIgnored @Injected(
    \.userUseCase
  ) private var userUseCase: UserUseCaseProtocol?
  @ObservationIgnored @Injected(
    \.crashlyticsService
  ) private var crashlyticsService: CrashlyticsServiceProtocol?
  @ObservationIgnored @Injected(
    \.analyticsService
  ) private var analyticsService: AnalyticsServiceProtocol?

  // Called on every appearance of the search list, including when a pushed screen pops,
  // so it must leave a pending search alone unless the semester really changed.
  func bind(selectedSemester: Semester) {
    guard self.selectedSemester != selectedSemester else { return }
    self.selectedSemester = selectedSemester
    restartSearch()
  }

  func retry() {
    restartSearch()
  }

  func fetchDepartments() async {
    guard let lectureUseCase, departments.isEmpty else { return }

    departmentState = .loading
    do {
      async let interestedIDs = fetchInterestedDepartmentIDs()
      departments = try await lectureUseCase.fetchDepartmentOptions()
      interestedDepartmentIDs = await interestedIDs
      departmentState = .loaded
    } catch {
      crashlyticsService?.recordException(error: error)
      departmentState = .error(message: error.localizedDescription)
    }
  }

  func loadMore() async {
    guard canLoadMore, let lectureUseCase, let selectedSemester else { return }
    let generation = searchGeneration

    do {
      let page = try await lectureUseCase.searchLecture(
        request: request(for: lastQuery, semester: selectedSemester, offset: loadedLectureCount)
      )
      guard !Task.isCancelled, generation == searchGeneration else { return }
      courses = courses.appending(page: page)
      canLoadMore = page.lectureCount == Self.pageSize
    } catch {
      guard !Task.isCancelled, generation == searchGeneration else { return }
      crashlyticsService?.recordException(error: error)
      canLoadMore = false
    }
  }

  // MARK: - Private
  // Only changes the order of the picker, so a failure here is not worth surfacing.
  private func fetchInterestedDepartmentIDs() async -> Set<Int> {
    guard let userUseCase else { return [] }

    if await userUseCase.otlUser == nil {
      try? await userUseCase.fetchOTLUser()
    }
    return Set(await userUseCase.otlUser?.interestedDepartments.map(\.id) ?? [])
  }

  private func restartSearch() {
    lastQuery = Query()
    courses.removeAll()
    state = .loading
    scheduleSearch()
  }

  private func scheduleSearch() {
    let query = currentQuery
    guard query != lastQuery else { return }

    // Results for a different set of filters would be misleading, so they go at once.
    // Keyword edits keep the previous results on screen until the new ones arrive.
    if query.filter != lastQuery.filter || query.isEmpty || state != .loaded {
      courses.removeAll()
      state = .loading
    }
    lastQuery = query
    searchGeneration += 1
    canLoadMore = false

    searchTask?.cancel()
    guard !query.isEmpty else { return }
    searchTask = Task { [weak self, generation = searchGeneration] in
      try? await Task.sleep(for: .milliseconds(350))
      guard !Task.isCancelled, let self else { return }
      await self.fetchLectures(query: query, generation: generation)
    }
  }

  private func fetchLectures(query: Query, generation: Int) async {
    guard let lectureUseCase, let selectedSemester else { return }

    do {
      let page = try await lectureUseCase.searchLecture(
        request: request(for: query, semester: selectedSemester, offset: 0)
      )
      guard generation == searchGeneration else { return }
      self.courses = page
      self.canLoadMore = page.lectureCount == Self.pageSize
      self.state = .loaded
      analyticsService?.logEvent(LectureSearchViewEvent.lecturesSearched)
    } catch {
      guard generation == searchGeneration else { return }
      crashlyticsService?.recordException(error: error)
      state = .error(message: error.localizedDescription)
    }
  }

  private func request(for query: Query, semester: Semester, offset: Int) -> LectureSearchRequest {
    LectureSearchRequest(
      semester: semester,
      keyword: query.keyword,
      filter: query.filter,
      limit: Self.pageSize,
      offset: offset
    )
  }
}

private extension Array where Element == CourseLecture {
  var lectureCount: Int {
    reduce(0) { $0 + $1.lectures.count }
  }
}
