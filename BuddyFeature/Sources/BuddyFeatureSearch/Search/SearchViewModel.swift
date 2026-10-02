//
//  SearchViewModel.swift
//  soap
//
//  Created by Soongyu Kwon on 26/09/2025.
//

import SwiftUI
import Observation
import Factory
import BuddyDomain
import os

private let logger = Logger(subsystem: "org.sparcs.soap", category: "SearchViewModel")

@MainActor
@Observable
class SearchViewModel {
  // MARK: - Properties
  enum ViewState: Equatable {
    case loading
    case loaded
    case error(message: String)
  }
  var courses: [CourseSummary] = []
  var posts: [AraPost] = []
  var taxiRooms: [TaxiRoom] = []

  var state: ViewState = .loaded

  // Infinite Scroll Properties
  var isLoadingMore: Bool = false
  var hasMorePages: Bool = true
  var currentPage: Int = 1
  var totalPages: Int = 0
  var pageSize: Int = 30
  private(set) var hasMoreCourses: Bool = false
  @ObservationIgnored private var isLoadingMoreCourses: Bool = false
  @ObservationIgnored private var courseOffset: Int = 0
  private static let coursePageSize = 150

  // Search Properties
  var searchText: String = "" {
    didSet { scheduleSearch() }
  }
  var searchScope: SearchScope = .all {
    didSet {
      if searchScope != oldValue { scopeDidChange() }
    }
  }

  // Course Filter Properties
  var courseFilter = LectureSearchFilter() {
    didSet { scheduleSearch() }
  }
  var coursePeriod: CourseSearchPeriod? {
    didSet { scheduleSearch() }
  }
  private(set) var departments: [DepartmentOption] = []
  /// The user's interested departments from Settings, listed first in the department picker.
  private(set) var interestedDepartmentIDs: Set<Int> = []
  private(set) var departmentState: DepartmentOptionsViewState = .loading

  /// Whether there is anything to search for: a keyword, or course filters in the Courses scope.
  var hasCriteria: Bool { !courseQuery.isEmpty }

  /// Departments chosen in the course filter, in the order the server lists them.
  var selectedDepartments: [DepartmentOption] {
    departments.filter { courseFilter.departmentIDs.contains($0.id) }
  }

  private struct CourseQuery: Equatable {
    var keyword: String = ""
    var filter = LectureSearchFilter()
    var period: CourseSearchPeriod?

    var isEmpty: Bool { keyword.isEmpty && filter.isEmpty && period == nil }
  }

  @ObservationIgnored private var searchTask: Task<Void, Never>?
  @ObservationIgnored private var lastKeyword: String = ""
  @ObservationIgnored private var lastCourseQuery = CourseQuery()
  /// Set when the keyword changes, because posts and rides then need fetching again too.
  /// A filter change on its own only refetches courses.
  @ObservationIgnored private var needsFullFetch: Bool = false
  /// Bumped for every new fetch so a slow response cannot overwrite a newer one.
  @ObservationIgnored private var fetchGeneration = 0

  private var keyword: String {
    searchText.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  // The filters belong to the Courses scope, the only place their chips are shown; the course
  // preview in the All scope stays a plain keyword search.
  private var courseQuery: CourseQuery {
    searchScope == .courses
      ? CourseQuery(keyword: keyword, filter: courseFilter, period: coursePeriod)
      : CourseQuery(keyword: keyword)
  }

  // MARK: - Dependencies
  @ObservationIgnored @Injected(\.araBoardUseCase) private var araBoardUseCase: AraBoardUseCaseProtocol?
  @ObservationIgnored @Injected(
    \.taxiRoomRepository
  ) private var taxiRoomRepository: TaxiRoomRepositoryProtocol?
  @ObservationIgnored @Injected(\.taxiLocationUseCase) private var taxiLocationUseCase: TaxiLocationUseCaseProtocol?
  @ObservationIgnored @Injected(
    \.v2CourseUseCase
  ) private var courseUseCase: CourseUseCaseProtocol?
  @ObservationIgnored @Injected(
    \.v2LectureUseCase
  ) private var lectureUseCase: LectureUseCaseProtocol?
  @ObservationIgnored @Injected(\.userUseCase) private var userUseCase: UserUseCaseProtocol?

  // MARK: - Functions
  func fetchDepartments() async {
    guard let lectureUseCase, departments.isEmpty else { return }

    departmentState = .loading
    do {
      async let interestedIDs = fetchInterestedDepartmentIDs()
      departments = try await lectureUseCase.fetchDepartmentOptions()
      interestedDepartmentIDs = await interestedIDs
      departmentState = .loaded
    } catch {
      logger.error("Failed to load departments: \(error.localizedDescription, privacy: .public)")
      departmentState = .error(message: error.localizedDescription)
    }
  }

  /// Reloads every section for the current search.
  func scopedFetch() async {
    needsFullFetch = true
    fetchGeneration += 1
    await fetchAll(generation: fetchGeneration)
  }

  func loadAraNextPage() async {
    guard !isLoadingMore && hasMorePages else { return }
    guard let araBoardUseCase else { return }

    isLoadingMore = true

    do {
      let nextPage = currentPage + 1
      let page = try await araBoardUseCase.fetchPosts(
        type: .all,
        page: nextPage,
        pageSize: pageSize,
        searchKeyword: searchText
      )
      self.currentPage = page.currentPage
      self.posts.append(contentsOf: page.results)
      self.hasMorePages = currentPage < totalPages
      self.state = .loaded
      self.isLoadingMore = false
    } catch {
      logger.error("Failed to load search results: \(error.localizedDescription, privacy: .public)")
      self.state = .error(message: error.localizedDescription)
      self.isLoadingMore = false
    }
  }

  func loadCoursesNextPage() async {
    guard hasMoreCourses, !isLoadingMoreCourses, let courseUseCase else { return }

    isLoadingMoreCourses = true
    defer { isLoadingMoreCourses = false }
    let generation = fetchGeneration

    do {
      let page = try await courseUseCase.searchCourse(request: request(for: lastCourseQuery, offset: courseOffset))
      guard generation == fetchGeneration else { return }
      let knownIDs = Set(courses.map(\.id))
      courses.append(contentsOf: page.filter { !knownIDs.contains($0.id) })
      courseOffset += page.count
      hasMoreCourses = page.count == Self.coursePageSize
    } catch {
      guard generation == fetchGeneration else { return }
      logger.error("Failed to load more courses: \(error.localizedDescription, privacy: .public)")
      hasMoreCourses = false
    }
  }

  // MARK: - Private
  private func scheduleSearch() {
    let keyword = self.keyword
    let courseQuery = self.courseQuery
    guard keyword != lastKeyword || courseQuery != lastCourseQuery else { return }

    if keyword != lastKeyword {
      needsFullFetch = true
    }
    lastKeyword = keyword
    lastCourseQuery = courseQuery
    startFetch(debounced: true)
  }

  private func scopeDidChange() {
    let courseQuery = self.courseQuery
    let courseQueryChanged = courseQuery != lastCourseQuery
    lastCourseQuery = courseQuery

    // Going back to All reloads every section.
    if searchScope == .all, !keyword.isEmpty {
      needsFullFetch = true
    }
    if needsFullFetch || courseQueryChanged {
      startFetch(debounced: false)
    } else {
      state = .loaded
    }
  }

  private func startFetch(debounced: Bool) {
    searchTask?.cancel()
    fetchGeneration += 1

    guard hasCriteria else {
      courses.removeAll()
      posts.removeAll()
      taxiRooms.removeAll()
      hasMoreCourses = false
      state = .loaded
      return
    }
    state = .loading

    searchTask = Task { [weak self, generation = fetchGeneration] in
      if debounced {
        try? await Task.sleep(for: .milliseconds(350))
      }
      guard !Task.isCancelled, let self, generation == self.fetchGeneration else { return }
      if self.needsFullFetch {
        await self.fetchAll(generation: generation)
      } else {
        await self.fetchCourses(generation: generation)
      }
    }
  }

  private func fetchAll(generation: Int) async {
    guard let taxiRoomRepository, let araBoardUseCase, let taxiLocationUseCase else { return }
    let keyword = self.keyword

    // Posts and rides are only ever matched by keyword.
    guard !keyword.isEmpty else {
      posts.removeAll()
      taxiRooms.removeAll()
      hasMorePages = false
      needsFullFetch = false
      await fetchCourses(generation: generation)
      return
    }
    state = .loading

    do {
      let postPage = try await araBoardUseCase.fetchPosts(
        type: .all,
        page: 1,
        pageSize: pageSize,
        searchKeyword: keyword
      )
      let fetchedRooms = try await taxiRoomRepository.fetchRooms()

      try await taxiLocationUseCase.fetchLocations()
      let matchedLocations = await taxiLocationUseCase.queryLocation(keyword)

      var added: Set<TaxiRoom> = []
      var matchedRooms: [TaxiRoom] = []

      for room in fetchedRooms {
        for location in matchedLocations {
          if (room.source.id == location.id || room.destination.id == location.id) && added.insert(room).inserted {
            matchedRooms.append(room)
          }
        }
        if room.title.lowercased().contains(keyword.lowercased()) && added.insert(room).inserted {
          matchedRooms.append(room)
        }
      }

      guard generation == fetchGeneration else { return }
      self.totalPages = postPage.pages
      self.currentPage = postPage.currentPage
      self.posts = postPage.results
      self.hasMorePages = currentPage < totalPages
      self.taxiRooms = matchedRooms
      self.needsFullFetch = false

      await fetchCourses(generation: generation)
    } catch {
      guard generation == fetchGeneration else { return }
      logger.error("Failed to load search results: \(error.localizedDescription, privacy: .public)")
      state = .error(message: error.localizedDescription)
    }
  }

  private func fetchCourses(generation: Int) async {
    guard let courseUseCase else { return }
    let query = lastCourseQuery
    state = .loading

    do {
      let page = try await courseUseCase.searchCourse(request: request(for: query, offset: 0))
      guard generation == fetchGeneration else { return }
      self.courses = page
      self.courseOffset = page.count
      self.hasMoreCourses = page.count == Self.coursePageSize
      self.state = .loaded
    } catch {
      guard generation == fetchGeneration else { return }
      logger.error("Failed to load courses: \(error.localizedDescription, privacy: .public)")
      state = .error(message: error.localizedDescription)
    }
  }

  private func request(for query: CourseQuery, offset: Int) -> CourseSearchRequest {
    CourseSearchRequest(
      keyword: query.keyword,
      filter: query.filter,
      period: query.period,
      limit: Self.coursePageSize,
      offset: offset
    )
  }

  // Only changes the order of the picker, so a failure here is not worth surfacing.
  private func fetchInterestedDepartmentIDs() async -> Set<Int> {
    guard let userUseCase else { return [] }

    if await userUseCase.otlUser == nil {
      try? await userUseCase.fetchOTLUser()
    }
    return Set(await userUseCase.otlUser?.interestedDepartments.map(\.id) ?? [])
  }
}
