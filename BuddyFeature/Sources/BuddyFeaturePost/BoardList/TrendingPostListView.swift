//
//  TrendingPostListView.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 24/10/2026.
//

import SwiftUI
import Observation
import Factory
import BuddyDomain
import BuddyFeatureShared
import os

private let logger = Logger(subsystem: "org.sparcs.soap", category: "TrendingPostListView")

/// Every trending post: the past week's, most viewed first.
struct TrendingPostListView: View {
  @State private var viewModel: TrendingPostListViewModelProtocol
  @State private var selectedPost: AraPost?

  init(viewModel: TrendingPostListViewModelProtocol = TrendingPostListViewModel()) {
    _viewModel = State(initialValue: viewModel)
  }

  var body: some View {
    Group {
      if let message = viewModel.errorMessage {
        ContentUnavailableView(
          String(localized: "Error", bundle: .module),
          systemImage: "wifi.exclamationmark",
          description: Text(message)
        )
      } else {
        PostList(
          posts: viewModel.posts,
          isLoadingMore: viewModel.isLoadingMore,
          onRefresh: { await viewModel.fetchInitialPosts() },
          onLoadMore: { viewModel.loadNextPage() },
          // Pushed by item, like the Boards list's own trending posts.
          onSelect: { selectedPost = $0 }
        )
        .contentWidth()
      }
    }
    .navigationDestination(item: $selectedPost) { post in
      PostView(post: post)
        .addKeyboardVisibilityToEnvironment()
    }
    .navigationTitle(String(localized: "Trending", bundle: .module))
    .navigationBarTitleDisplayMode(.inline)
    .toolbar(.hidden, for: .tabBar)
    .background {
      BackgroundGradientView(color: .red)
        .ignoresSafeArea()
    }
    .scrollContentBackground(.hidden)
    .task {
      if viewModel.posts == nil {
        await viewModel.fetchInitialPosts()
      }
    }
  }
}

@MainActor
protocol TrendingPostListViewModelProtocol: Observable {
  /// `nil` until the first page loads.
  var posts: [AraPost]? { get }
  var isLoadingMore: Bool { get }
  var errorMessage: String? { get }

  func fetchInitialPosts() async
  func loadNextPage()
}

@Observable
final class TrendingPostListViewModel: TrendingPostListViewModelProtocol {
  private(set) var posts: [AraPost]?
  private(set) var isLoadingMore = false
  private(set) var errorMessage: String?

  @ObservationIgnored private var currentPage = 1
  @ObservationIgnored private var totalPages = 1
  private let pageSize = 30

  @ObservationIgnored @Injected(
    \.araBoardUseCase
  ) private var araBoardUseCase: AraBoardUseCaseProtocol?

  func fetchInitialPosts() async {
    guard let araBoardUseCase else { return }
    do {
      let page = try await araBoardUseCase.fetchPosts(type: .trending, page: 1, pageSize: pageSize, searchKeyword: nil)
      currentPage = page.currentPage
      totalPages = page.pages
      posts = page.results
      errorMessage = nil
    } catch {
      logger.error("Failed to load trending posts: \(error.localizedDescription, privacy: .public)")
      errorMessage = error.localizedDescription
    }
  }

  func loadNextPage() {
    guard !isLoadingMore, currentPage < totalPages, let araBoardUseCase else { return }
    isLoadingMore = true
    let nextPage = currentPage + 1
    Task {
      defer { isLoadingMore = false }
      do {
        let page = try await araBoardUseCase.fetchPosts(type: .trending, page: nextPage, pageSize: pageSize, searchKeyword: nil)
        currentPage = page.currentPage
        posts = (posts ?? []) + page.results
      } catch {
        logger.error("Failed to load more trending posts: \(error.localizedDescription, privacy: .public)")
      }
    }
  }
}
