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
  /// When the lectures meet. Separate from `filter`, which course search shares and cannot use.
  var time = LectureTimeFilter() {
    didSet { scheduleSearch() }
  }

  private(set) var departments: [DepartmentOption] = []
  /// The user's interested departments from Settings, listed first in the department picker.
  private(set) var interestedDepartmentIDs: Set<Int> = []
  private(set) var departmentState: DepartmentOptionsViewState = .loading
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
    var time = LectureTimeFilter()

    var isEmpty: Bool { keyword.isEmpty && filter.isEmpty && time.isEmpty }
  }

  private static let pageSize = 100

  @ObservationIgnored private var searchTask: Task<Void, Never>?
  @ObservationIgnored private var lastQuery = Query()
  /// Bumped for every new search so a slow response cannot overwrite a newer one.
  @ObservationIgnored private var searchGeneration = 0
  @ObservationIgnored private var selectedSemester: Semester?

  /// The semester's wishlisted lectures, shown while there is nothing to search for.
  var wishlist: [CourseLecture] {
    pendingWishlistChanges.reduce(savedWishlist) { courses, change in
      change.value ? courses : courses.removing(lectureID: change.key)
    }
  }
  /// Wishlisted lecture IDs, updated as soon as a heart is tapped.
  var wishlistedLectureIDs: Set<Int> {
    pendingWishlistChanges.reduce(into: savedWishlistIDs) { ids, change in
      if change.value { ids.insert(change.key) } else { ids.remove(change.key) }
    }
  }
  /// Set when a wishlist change fails, for the view to report.
  var wishlistError: String?

  /// The wishlist as the server last returned it, plus the changes saved since.
  private var savedWishlist: [CourseLecture] = []
  private var savedWishlistIDs: Set<Int> = []
  /// Lectures whose wishlist change is still being saved, and whether each is being added.
  /// Laid over the saved wishlist so a fetch that lands meanwhile cannot undo the tap.
  private var pendingWishlistChanges: [Int: Bool] = [:]
  /// Bumped for every saved change so a fetch that read the server before it can tell.
  @ObservationIgnored private var wishlistGeneration = 0

  private var currentQuery: Query {
    Query(keyword: searchKeyword.trimmingCharacters(in: .whitespacesAndNewlines), filter: filter, time: time)
  }

  // MARK: - Dependencies
  @ObservationIgnored @Injected(
    \.v2LectureUseCase
  ) private var lectureUseCase: LectureUseCaseProtocol?
  @ObservationIgnored @Injected(
    \.userUseCase
  ) private var userUseCase: UserUseCaseProtocol?
  @ObservationIgnored @Injected(
    \.wishlistUseCase
  ) private var wishlistUseCase: WishlistUseCaseProtocol?
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
    // Another semester's wishlist would be wrong until its own arrives.
    if self.selectedSemester != nil {
      savedWishlist = []
      savedWishlistIDs = []
    }
    self.selectedSemester = selectedSemester
    restartSearch()
  }

  func retry() {
    restartSearch()
  }

  // MARK: - Wishlist

  func isWishlisted(_ lecture: Lecture) -> Bool {
    wishlistedLectureIDs.contains(lecture.id)
  }

  func fetchWishlist(semester: Semester) async {
    guard let wishlistUseCase else { return }
    do {
      // A change saved while this was in flight may be missing from the response, and nothing
      // else fetches after a removal, so a response that may be stale is fetched again.
      var courses: [CourseLecture]
      var generation: Int
      repeat {
        generation = wishlistGeneration
        courses = try await wishlistUseCase.fetchWishlist(semester: semester)
      } while generation != wishlistGeneration
      guard semester == selectedSemester || selectedSemester == nil else { return }
      savedWishlist = courses
      savedWishlistIDs = Set(courses.flatMap { $0.lectures.map(\.id) })
    } catch {
      // The wishlist is extra; search works without it, so a failure stays quiet.
      crashlyticsService?.recordException(error: error)
    }
  }

  /// Flips a lecture's wishlist state at once, then saves it, undoing the change if that fails.
  func toggleWishlist(_ lecture: Lecture) async {
    // Taps on a lecture whose change is still saving are ignored: a second request racing the
    // first, or the fetch after it, could leave the heart disagreeing with the server.
    guard let wishlistUseCase, pendingWishlistChanges[lecture.id] == nil else { return }
    let isAdding = !isWishlisted(lecture)
    pendingWishlistChanges[lecture.id] = isAdding
    defer { pendingWishlistChanges[lecture.id] = nil }
    analyticsService?.logEvent(isAdding ? LectureSearchViewEvent.lectureWishlisted : LectureSearchViewEvent.lectureUnwishlisted)

    do {
      try await wishlistUseCase.setWishlisted(isAdding, lectureID: lecture.id)
    } catch {
      crashlyticsService?.recordException(error: error)
      wishlistError = error.localizedDescription
      return
    }
    wishlistGeneration += 1
    if isAdding {
      savedWishlistIDs.insert(lecture.id)
    } else {
      savedWishlistIDs.remove(lecture.id)
      savedWishlist = savedWishlist.removing(lectureID: lecture.id)
    }
    // An added lecture needs its course from the server to appear in the list.
    if isAdding, let selectedSemester {
      await fetchWishlist(semester: selectedSemester)
    }
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
    if query.filter != lastQuery.filter || query.time != lastQuery.time || query.isEmpty || state != .loaded {
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
      time: query.time,
      limit: Self.pageSize,
      offset: offset
    )
  }
}

private extension Array where Element == CourseLecture {
  var lectureCount: Int {
    reduce(0) { $0 + $1.lectures.count }
  }

  /// Drops one lecture, and its course once it has none left.
  func removing(lectureID: Int) -> [CourseLecture] {
    compactMap { course in
      let lectures = course.lectures.filter { $0.id != lectureID }
      guard !lectures.isEmpty else { return nil }
      return CourseLecture(
        id: course.id, name: course.name, code: course.code, type: course.type,
        lectures: lectures, completed: course.completed
      )
    }
  }
}
