//
//  AraSettingsViewModel.swift
//  soap
//
//  Created by 하정우 on 8/28/25.
//

import SwiftUI
import Combine
import Observation
import Factory

@MainActor
protocol AraSettingsViewModelProtocol: Observable {
  var araUser: AraMe? { get }
  var araAllowNSFWPosts: Bool { get set }
  var araAllowPoliticalPosts: Bool { get set }
  var araNickname: String { get set }
  var araNicknameUpdatable: Bool { get }
  var araNicknameUpdatableSince: Date? { get }
  var state: AraSettingsViewModel.ViewState { get }
  var posts: [AraPost] { get }
  
  func fetchAraUser() async
  func updateAraNickname() async throws
  func updateAraPostVisibility() async
  func fetchInitialPosts() async
  func loadNextPage() async
  func refreshItem(postID: Int) 
}

@Observable
class AraSettingsViewModel: AraSettingsViewModelProtocol {
  enum ViewState {
    case loading
    case loaded
    case error(message: String)
  }
  
  enum PostType: String, CaseIterable {
    case all = "All"
    case bookmark = "Bookmarked"
  }
  
  // MARK: - Dependencies
  @ObservationIgnored @Injected(\.userUseCase) private var userUseCase: UserUseCaseProtocol
  @ObservationIgnored @Injected(\.araBoardRepository) private var araBoardRepository: AraBoardRepositoryProtocol

  // MARK: - Properties
  var araUser: AraMe?
  var araAllowNSFWPosts: Bool = false
  var araAllowPoliticalPosts: Bool = false
  var araNickname: String = ""
  var araNicknameUpdatable: Bool {
    if let date = araNicknameUpdatableSince, date <= Date() {
      return true
    }
    return false
  }
  var araNicknameUpdatableSince: Date? {
    if let nicknameUpdatedAt = araUser?.nicknameUpdatedAt, let date = Calendar.current.date(byAdding: .month, value: 3, to: nicknameUpdatedAt) {
      return date
    }
    return nil
  }
  var state: ViewState = .loading
  var posts: [AraPost] = []
  
  // Infinite Scroll Properties
  var isLoadingMore: Bool = false
  var hasMorePages: Bool = true
  var currentPage: Int = 1
  var totalPages: Int = 0
  var pageSize: Int = 30
  
  // MARK: - Functions
  func fetchAraUser() async {
    state = .loading
    do {
      try await userUseCase.fetchAraUser()
    } catch {
      state = .error(message: error.localizedDescription)
    }
    self.araUser = await userUseCase.araUser
    araAllowNSFWPosts = araUser?.allowNSFW ?? false
    araAllowPoliticalPosts = araUser?.allowPolitical ?? false
    araNickname = araUser?.nickname ?? ""
    state = .loaded
  }
  
  func updateAraNickname() async throws {
    try await userUseCase.updateAraUser(params: ["nickname": araNickname])
  }
  
  func updateAraPostVisibility() async {
    do {
      try await userUseCase.updateAraUser(params: ["see_sexual": araAllowNSFWPosts, "see_social": araAllowPoliticalPosts])
    } catch {
      logger.debug("Failed to update ara post visibility: \(error)")
    }
  }
  
  func fetchInitialPosts() async {
    guard let userID = araUser?.id else { return }
    
    do {
      self.state = .loading
      let page = try await araBoardRepository.fetchPosts(
        type: .user(userID: userID),
        page: 1,
        pageSize: pageSize,
        searchKeyword: nil)
      self.totalPages = page.pages
      self.currentPage = page.currentPage
      self.posts = page.results
      self.hasMorePages = currentPage < totalPages
      self.state = .loaded
    } catch {
      logger.error(error)
      state = .error(message: error.localizedDescription)
    }
  }
  
  func loadNextPage() async {
    guard let userID = araUser?.id else { return }
    guard !isLoadingMore && hasMorePages else { return }
    
    isLoadingMore = true
    
    do {
      let nextPage = currentPage + 1
      let page = try await araBoardRepository.fetchPosts(
        type: .user(userID: userID),
        page: nextPage,
        pageSize: pageSize,
        searchKeyword: nil
      )
      self.totalPages = page.pages
      self.currentPage = page.currentPage
      self.posts.append(contentsOf: page.results)
      self.hasMorePages = currentPage < totalPages
      self.state = .loaded
      self.isLoadingMore = false
    } catch {
      logger.error(error)
      state = .error(message: error.localizedDescription)
    }
  }
  
  func refreshItem(postID: Int) {
    Task {
      guard let updated: AraPost = try? await araBoardRepository.fetchPost(origin: .none, postID: postID) else { return }
      
      if let idx = self.posts.firstIndex(where: { $0.id == updated.id }) {
        var previousPost: AraPost = self.posts[idx]
        previousPost.upvotes = updated.upvotes
        previousPost.downvotes = updated.downvotes
        previousPost.commentCount = updated.commentCount
        self.posts[idx] = previousPost
        self.state = .loaded
      }
    }
  }
}
