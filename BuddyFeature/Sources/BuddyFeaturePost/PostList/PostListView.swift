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

  @State private var loadedInitialPost: Bool = false

  init(board: AraBoard) {
    _viewModel = State(initialValue: PostListViewModel(board: board))
  }

  init(viewModel: PostListViewModelProtocol) {
    _viewModel = State(initialValue: viewModel)
  }

  var body: some View {
    Group {
      switch viewModel.state {
      case .loading:
        PostList(
          posts: nil,
          isLoadingMore: false,
          onRefresh: nil,
          onLoadMore: nil
        )
      case .loaded(let posts):
        if viewModel.posts.isEmpty && !viewModel.searchKeyword.isEmpty {
          ContentUnavailableView.search(text: viewModel.searchKeyword)
        } else {
          PostList(
            posts: posts,
            isLoadingMore: viewModel.isLoadingMore,
            onRefresh: {
              await viewModel.fetchInitialPosts()
            },
            onLoadMore: {
              viewModel.loadNextPage()
            }
          )
        }
      case .error(let message):
        ContentUnavailableView(String(localized: "Error", bundle: .module), systemImage: "wifi.exclamationmark", description: Text(message))
      }
    }
    .navigationDestination(for: AraPost.self) { post in
      PostView(post: post, onPostDeleted: { postID in
        viewModel.removePost(postID: postID)
      })
      .id(post.id)
      .addKeyboardVisibilityToEnvironment()
      .onDisappear {
        viewModel.refreshItem(postID: post.id)
      }
    }
    .transition(.opacity.animation(.easeInOut(duration: 0.3)))
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


