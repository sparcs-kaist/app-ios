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

@MainActor
@Observable
class SearchViewModel {
  // MARK: - Properties
  enum ViewState: Equatable {
    case loading
    case loaded(courses: [Course], posts: [AraPost], taxiRooms: [TaxiRoom])
    case error(message: String)
  }
  var courses: [Course] = []
  var posts: [AraPost] = []
  var taxiRooms: [TaxiRoom] = []
  
  var state: ViewState = .loaded(courses: [], posts: [], taxiRooms: [])
  
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
  @ObservationIgnored @Injected(\.araBoardRepository) private var araBoardRepository: AraBoardRepositoryProtocol
  @ObservationIgnored @Injected(\.taxiRoomRepository) private var taxiRoomRepository: TaxiRoomRepositoryProtocol
  
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
        Task {
          switch searchScope {
          case .all:
            await self.fetchInitialData()
          case .courses:
            self.fetchCourseAll()
          case .posts:
            await self.fetchPostAll()
          case .taxi:
            await self.fetchTaxiAll()
          }
        }
      }
      .store(in: &cancellables)
  }
  
  func fetchInitialData() async {
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
      self.taxiRooms = try await taxiRoomRepository.searchRooms(name: searchText)
      
      let posts = Array(self.posts.prefix(self.posts.count > 3 ? 3 : self.posts.count))
      let rooms = Array(self.taxiRooms.prefix(self.taxiRooms.count > 3 ? 3 : self.taxiRooms.count))
      
      // TODO: OTL API CALL
      self.courses = Course.mockList
      
      logger.debug("Courses: \(self.courses), Posts: \(posts), Taxi Rooms: \(rooms)")
      
      self.state = .loaded(courses: self.courses, posts: posts, taxiRooms: rooms)
    } catch {
      state = .error(message: error.localizedDescription)
      logger.error(error)
    }
  }
  
  func loadAraNextPage() async {
    guard !isLoadingMore && hasMorePages else { return }
    
    self.state = .loading
    
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
      self.state = .loaded(courses: self.courses, posts: self.posts, taxiRooms: self.taxiRooms)
      self.isLoadingMore = false
    } catch {
      logger.error(error)
      self.state = .error(message: error.localizedDescription)
      self.isLoadingMore = false
    }
  }
  
  func fetchPostAll() async {
    self.state = .loaded(courses: self.courses, posts: self.posts, taxiRooms: self.taxiRooms)
  }
  
  func fetchTaxiAll() async {
    self.state = .loaded(courses: self.courses, posts: self.posts, taxiRooms: self.taxiRooms)
  }
  
  func fetchCourseAll() {
    self.state = .loaded(courses: self.courses, posts: self.posts, taxiRooms: self.taxiRooms)
  }
}
