//
//  PostListView.swift
//  soap
//
//  Created by Soongyu Kwon on 05/01/2025.
//

import Foundation
import SwiftUI
import Observation
import BuddyDomain
import BuddyFeatureShared
import BuddyPreviewSupport
import FirebaseAnalytics

struct PostListView: View {
  @State private var viewModel: PostListViewModelProtocol

  @State private var showsComposeView: Bool = false
  @Namespace private var namespace
  @Namespace private var postTransition

  @State private var loadedInitialPost: Bool = false

  init(board: AraBoard) {
    _viewModel = State(initialValue: PostListViewModel(board: board))
  }

  init(viewModel: PostListViewModelProtocol) {
    _viewModel = State(initialValue: viewModel)
  }

  /// The Market board shows its listings as a grid with prices; other boards as a list.
  @ViewBuilder
  private func posts(_ posts: [AraPost]?) -> some View {
    if viewModel.board.isMarket {
      // A grid uses every point, unlike a list's reading-width column.
      MarketGrid(
        posts: posts,
        isLoadingMore: viewModel.isLoadingMore,
        onRefresh: { await viewModel.fetchInitialPosts() },
        onLoadMore: { viewModel.loadNextPage() },
        transitionNamespace: postTransition
      )
    } else {
      PostList(
        posts: posts,
        isLoadingMore: viewModel.isLoadingMore,
        onRefresh: posts == nil ? nil : { await viewModel.fetchInitialPosts() },
        onLoadMore: posts == nil ? nil : { viewModel.loadNextPage() }
      )
      .contentWidth()
    }
  }

  var body: some View {
    Group {
      switch viewModel.state {
      case .loading:
        posts(nil)
      case .loaded(let posts):
        if viewModel.posts.isEmpty && !viewModel.searchKeyword.isEmpty {
          ContentUnavailableView.search(text: viewModel.searchKeyword)
        } else {
          self.posts(posts)
        }
      case .error(let message):
        ContentUnavailableView(String(localized: "Error", bundle: .module), systemImage: "wifi.exclamationmark", description: Text(message))
      }
    }
    .navigationDestination(for: AraPost.self) { post in
      PostView(post: post, onPostDeleted: { postID in
        viewModel.removePost(postID: postID)
      })
      // Market posts zoom out of their photo in the grid.
      .modifier(MarketZoomTransition(isEnabled: viewModel.board.isMarket, postID: post.id, namespace: postTransition))
      .id(post.id)
      .addKeyboardVisibilityToEnvironment()
      .onAppear {
        viewModel.markRead(postID: post.id)
      }
      .onDisappear {
        viewModel.refreshItem(postID: post.id)
      }
    }
    .transition(.opacity.animation(.easeInOut(duration: 0.3)))
    .safeAreaBar(edge: .top) {
      if let topics = viewModel.board.topics, !topics.isEmpty {
        TopicFilterBar(topics: topics, selection: $viewModel.selectedTopic)
      }
    }
    // Content blurs softly behind the chips rather than under a hard edge.
    .scrollEdgeEffectStyle(.soft, for: .top)
    .disabled(viewModel.state == .loading)
    .navigationTitle(viewModel.board.name.localized())
    .navigationSubtitle(viewModel.board.group.name.localized())
    .navigationBarTitleDisplayMode(.inline)
    .toolbar(.hidden, for: .tabBar)
    .toolbar {
      DefaultToolbarItem(kind: .search, placement: .bottomBar)

      if !viewModel.board.isReadOnly && viewModel.board.userWritable == true {
        ToolbarSpacer(.flexible, placement: .bottomBar)
        ToolbarItem(placement: .bottomBar) {
          Button(String(localized: "Write", bundle: .module), systemImage: "square.and.pencil") {
            showsComposeView = true
          }
        }
        .matchedTransitionSource(id: "ComposeView", in: namespace)
      }
    }
    .sheet(isPresented: $showsComposeView, onDismiss: {
      Task {
        await viewModel.fetchInitialPosts()
      }
    }) {
      PostComposeView(board: viewModel.board)
        .interactiveDismissDisabled()
        .navigationTransition(.zoom(sourceID: "ComposeView", in: namespace))
    }
    .task {
      if !loadedInitialPost {
        viewModel.bind()
        await viewModel.fetchInitialPosts()
        loadedInitialPost = true
      }
    }
    .searchable(text: $viewModel.searchKeyword)
    .background {
      BackgroundGradientView(color: .red)
        .ignoresSafeArea()
    }
    .scrollContentBackground(.hidden)
    .analyticsScreen(name: "Ara Post List", class: String(describing: Self.self))
  }
}

#Preview("Loading State") {
  NavigationStack {
    PostListView(viewModel: PreviewPostListViewModel(state: .loading, board: .mock))
  }
}

#Preview("Loaded State") {
  NavigationStack {
    PostListView(viewModel: PreviewPostListViewModel(
      state: .loaded(posts: AraPost.mockList),
      board: .mock,
      posts: AraPost.mockList
    ))
  }
}

#Preview("Error State") {
  NavigationStack {
    PostListView(viewModel: PreviewPostListViewModel(
      state: .error(message: "Something went wrong"),
      board: .mock
    ))
  }
}

#Preview("Empty Search") {
  NavigationStack {
    PostListView(viewModel: PreviewPostListViewModel(
      state: .loaded(posts: []),
      board: .mock,
      posts: [],
      searchKeyword: "no results"
    ))
  }
}

/// Zooms a Market post out of its photo in the grid; other boards push as usual.
private struct MarketZoomTransition: ViewModifier {
  let isEnabled: Bool
  let postID: Int
  let namespace: Namespace.ID

  func body(content: Content) -> some View {
    if isEnabled {
      content.navigationTransition(.zoom(sourceID: postID, in: namespace))
    } else {
      content
    }
  }
}
