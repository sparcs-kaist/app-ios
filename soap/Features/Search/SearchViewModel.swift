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
            break
          case .posts:
            break
          case .taxi:
            await self.fetchTaxiAll()
          }
        }
      }
      .store(in: &cancellables)
  }
  
  func fetchInitialData() async {
    do {
      let postPage = try await araBoardRepository.fetchPosts(
        type: .all,
        page: 1,
        pageSize: 3,
        searchKeyword: searchText
      )
      self.posts = postPage.results
      self.taxiRooms = try await taxiRoomRepository.searchRooms(name: searchText)
      let rooms = Array(self.taxiRooms.prefix(self.taxiRooms.count > 3 ? 3 : self.taxiRooms.count))
      
      // TODO: OTL API CALL
      self.courses = Course.mockList
      
      logger.debug("Courses: \(self.courses), Posts: \(self.posts), Taxi Rooms: \(rooms)")
      
      self.state = .loaded(courses: self.courses, posts: self.posts, taxiRooms: rooms)
    } catch {
      state = .error(message: error.localizedDescription)
      logger.error(error)
    }
  }
  
  func fetchTaxiAll() async {
    self.state = .loading
    
    self.state = .loaded(courses: self.courses, posts: self.posts, taxiRooms: self.taxiRooms)
  }
}
