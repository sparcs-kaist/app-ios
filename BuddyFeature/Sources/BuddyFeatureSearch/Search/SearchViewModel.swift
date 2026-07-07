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
  
  // Search Properties
  var searchText: String = "" {
    didSet { scheduleSearch() }
  }
  var searchScope: SearchScope = .all
  @ObservationIgnored private var searchTask: Task<Void, Never>?
  @ObservationIgnored private var lastSearchKeyword: String?
  
  // MARK: - Dependencies
  @ObservationIgnored @Injected(\.araBoardUseCase) private var araBoardUseCase: AraBoardUseCaseProtocol?
  @ObservationIgnored @Injected(
    \.taxiRoomRepository
  ) private var taxiRoomRepository: TaxiRoomRepositoryProtocol?
  @ObservationIgnored @Injected(\.taxiLocationUseCase) private var taxiLocationUseCase: TaxiLocationUseCaseProtocol?
  @ObservationIgnored @Injected(
    \.v2CourseUseCase
  ) private var courseUseCase: CourseUseCaseProtocol?

  func bind() {
    searchTask?.cancel()
    lastSearchKeyword = nil
  }

  private func scheduleSearch() {
    let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard keyword != lastSearchKeyword else { return }
    lastSearchKeyword = keyword

    searchTask?.cancel()
    guard !searchText.isEmpty else { return }
    state = .loading

    searchTask = Task { [weak self] in
      try? await Task.sleep(for: .milliseconds(350))
      guard !Task.isCancelled, let self else { return }
      guard !self.searchText.isEmpty else { return }
      self.courses.removeAll()
      self.posts.removeAll()
      self.taxiRooms.removeAll()
      await self.scopedFetch()
    }
  }
  
  func fetchInitialData() async {
    guard let taxiRoomRepository, let araBoardUseCase, let courseUseCase, let taxiLocationUseCase else { return }
    state = .loading
    
    do {
      let postPage = try await araBoardUseCase.fetchPosts(
        type: .all,
        page: 1,
        pageSize: pageSize,
        searchKeyword: searchText
      )
      self.totalPages = postPage.pages
      self.currentPage = postPage.currentPage
      self.posts = postPage.results
      self.hasMorePages = currentPage < totalPages
      self.taxiRooms = []
      let fetchedRooms = try await taxiRoomRepository.fetchRooms()
      
      try await taxiLocationUseCase.fetchLocations()
      let matchedLocations = await taxiLocationUseCase.queryLocation(searchText)

      var added: Set<TaxiRoom> = []
      
      for room in fetchedRooms {
        for location in matchedLocations {
          if (room.source.id == location.id || room.destination.id == location.id) && added.insert(room).inserted {
            self.taxiRooms.append(room)
          }
        }
        if room.title.lowercased().contains(searchText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)) && added.insert(room).inserted {
          self.taxiRooms.append(room)
        }
      }

      let request = CourseSearchRequest(keyword: searchText, limit: 150, offset: 0)
      self.courses = try await courseUseCase.searchCourse(request: request)

      self.state = .loaded
    } catch {
      logger.error("Failed to load search results: \(error.localizedDescription, privacy: .public)")
      state = .error(message: error.localizedDescription)
    }
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
  
  func loadFull() {
    self.state = .loaded
  }
  
  func scopedFetch() async {
    await self.fetchInitialData()
    if searchScope != .all {
      self.loadFull()
    }
  }
}
