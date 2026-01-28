//
//  SearchViewModel.swift
//  soap
//
//  Created by Soongyu Kwon on 26/09/2025.
//

import SwiftUI
import Observation
import Combine
import Factory
import SwiftyBeaver
import BuddyDomain

@MainActor
@Observable
class SearchViewModel {
  // MARK: - Properties
  enum ViewState: Equatable {
    case loading
    case loaded
    case error(message: String)
  }
  var courses: [Course] = []
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
    didSet { searchKeywordSubject.send(searchText) }
  }
  var searchScope: SearchScope = .all
  @ObservationIgnored private var cancellables = Set<AnyCancellable>()
  @ObservationIgnored private let searchKeywordSubject = PassthroughSubject<String, Never>()
  
  // MARK: - Dependencies
  @ObservationIgnored @Injected(\.araBoardRepository) private var araBoardRepository: AraBoardRepositoryProtocol?
  @ObservationIgnored @Injected(
    \.taxiRoomRepository
  ) private var taxiRoomRepository: TaxiRoomRepositoryProtocol?
  @ObservationIgnored @Injected(\.taxiLocationUseCase) private var taxiLocationUseCase: TaxiLocationUseCaseProtocol
  @ObservationIgnored @Injected(\.otlCourseRepository) private var otlCourseRepository: OTLCourseRepositoryProtocol?

  func bind() {
    cancellables.removeAll()
    
    let searchPublisher = searchKeywordSubject
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .removeDuplicates()
    
    searchPublisher
      .sink { [weak self] _ in
        guard let self else { return }
        guard !searchText.isEmpty else { return }
        self.state = .loading
      }
      .store(in: &cancellables)
    
    searchPublisher
      .debounce(for: .milliseconds(350), scheduler: DispatchQueue.main)
      .sink { [weak self] _ in
        guard let self else { return }
        guard !searchText.isEmpty else { return }
        self.courses.removeAll()
        self.posts.removeAll()
        self.taxiRooms.removeAll()
        Task {
          await scopedFetch()
        }
      }
      .store(in: &cancellables)
  }
  
  func fetchInitialData() async {
    guard let taxiRoomRepository, let araBoardRepository, let otlCourseRepository else { return }
    state = .loading
    
    do {
      let postPage = try await araBoardRepository.fetchPosts(
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
      
      self.courses = try await otlCourseRepository.searchCourse(name: searchText, offset: 0, limit: 150)

      self.state = .loaded
    } catch {
      state = .error(message: error.localizedDescription)
      logger.error(error)
    }
  }
  
  func loadAraNextPage() async {
    guard !isLoadingMore && hasMorePages else { return }
    guard let araBoardRepository else { return }

    isLoadingMore = true
    
    do {
      let nextPage = currentPage + 1
      let page = try await araBoardRepository.fetchPosts(
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
      logger.error(error)
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
