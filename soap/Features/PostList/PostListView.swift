//
//  PostListView.swift
//  soap
//
//  Created by Soongyu Kwon on 05/01/2025.
//

import SwiftUI

struct PostListView: View {
  @State private var viewModel: PostListViewModelProtocol

  @State private var showsComposeView: Bool = false
  @Namespace private var namespace

  @State private var loadedInitialPost: Bool = false
  @State private var searchText: String = ""

  init(board: AraBoard) {
    _viewModel = State(initialValue: PostListViewModel(board: board))
  }

  var body: some View {
    Group {
      switch viewModel.state {
      case .loading:
        PostList(
          posts: nil,
          destination: { _ in
            EmptyView()
          }
        )
      case .loaded(let posts):
        PostList(
          posts: posts,
          destination: { post in
            PostView(post: post)
              .addKeyboardVisibilityToEnvironment()
              .onDisappear {
                viewModel.refreshItem(postID: post.id)
              }
          }, onRefresh: {
            await viewModel.fetchInitialPosts()
          }, onLoadMore: {
            await viewModel.loadNextPage()
          }
        )
      case .error(let message):
        ContentUnavailableView("Error", systemImage: "wifi.exclamationmark", description: Text(message))
      }
    }
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
          Button("Write", systemImage: "square.and.pencil") {
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
    .overlay(alignment: .center) {
      if !viewModel.searchKeyword.isEmpty && viewModel.posts.isEmpty {
        ContentUnavailableView.search(text: viewModel.searchKeyword)
      }
    }
  }
}

#Preview {
  NavigationStack {
    PostListView(board: AraBoard.mock)
  }
}



