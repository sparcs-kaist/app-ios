//
//  HighlightPostListView.swift
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

private let logger = Logger(subsystem: "org.sparcs.soap", category: "HighlightPostListView")

/// Every post of a highlight: the week's trending posts, or the newest, a page at a time.
struct HighlightPostListView: View {
  let highlight: BoardHighlight
  @State private var viewModel: HighlightPostListViewModelProtocol
  @State private var selectedPost: AraPost?

  init(highlight: BoardHighlight) {
    self.highlight = highlight
    _viewModel = State(initialValue: HighlightPostListViewModel(listType: highlight.listType))
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
          // Pushed by item, like the Boards list's own highlighted posts.
          onSelect: { selectedPost = $0 }
        )
        .contentWidth()
      }
    }
    .navigationDestination(item: $selectedPost) { post in
      PostView(post: post)
        .addKeyboardVisibilityToEnvironment()
    }
    .navigationTitle(highlight.title)
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
protocol HighlightPostListViewModelProtocol: Observable {
  /// `nil` until the first page loads.
  var posts: [AraPost]? { get }
  var isLoadingMore: Bool { get }
  var errorMessage: String? { get }

  func fetchInitialPosts() async
  func loadNextPage()
}

@Observable
final class HighlightPostListViewModel: HighlightPostListViewModelProtocol {
  private let listType: PostListType

  private(set) var posts: [AraPost]?
  private(set) var isLoadingMore = false
  private(set) var errorMessage: String?

  @ObservationIgnored private var currentPage = 1
  @ObservationIgnored private var totalPages = 1
  private let pageSize = 30

  init(listType: PostListType) {
    self.listType = listType
  }

  @ObservationIgnored @Injected(
    \.araBoardUseCase
  ) private var araBoardUseCase: AraBoardUseCaseProtocol?

  func fetchInitialPosts() async {
    guard let araBoardUseCase else { return }
    do {
      let page = try await araBoardUseCase.fetchPosts(type: listType, page: 1, pageSize: pageSize, searchKeyword: nil)
      currentPage = page.currentPage
      totalPages = page.pages
      posts = page.results
      errorMessage = nil
    } catch {
      logger.error("Failed to load posts: \(error.localizedDescription, privacy: .public)")
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
        let page = try await araBoardUseCase.fetchPosts(type: listType, page: nextPage, pageSize: pageSize, searchKeyword: nil)
        currentPage = page.currentPage
        posts = (posts ?? []) + page.results
      } catch {
        logger.error("Failed to load more posts: \(error.localizedDescription, privacy: .public)")
      }
    }
  }
}
