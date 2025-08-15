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
    List {
      switch viewModel.state {
      case .loading:
        loadingView
          .redacted(reason: .placeholder)
      case .loaded(let posts):
        loadedView(posts)
      case .error(let message):
        ContentUnavailableView("Error", systemImage: "wifi.exclamationmark", description: Text(message))
      }
    }
    .disabled(viewModel.state == .loading)
    .listStyle(.plain)
    .refreshable {
      await viewModel.fetchInitialPosts()
    }
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

  @ViewBuilder
  func loadedView(_ posts: [AraPost]) -> some View {
    ForEach(Array(posts.enumerated()), id: \.element.id) { index, post in
      PostListRow(post: post)
        .listRowSeparator(.hidden, edges: .top)
        .listRowSeparator(.visible, edges: .bottom)
        .background {
          if !post.isHidden {
            NavigationLink("", destination: {
              PostView(post: post, onPostDeleted: { deletedPostID in
                viewModel.removePost(postID: deletedPostID)
              })
                .onDisappear {
                  // on dismiss, refresh this item
                  viewModel.refreshItem(postID: post.id)
                }
                .addKeyboardVisibilityToEnvironment()
            })
              .opacity(0)
          }
        }
        .onAppear {
          // loads more contents on 60% scroll
          let thresholdIndex = Int(Double(posts.count) * 0.6)
          if index >= thresholdIndex && viewModel.hasMorePages && !viewModel.isLoadingMore {
            Task {
              await viewModel.loadNextPage()
            }
          }
        }
    }
    
    // Shows loding indicator on loading at the bottom
    if viewModel.isLoadingMore {
      HStack {
        Spacer()
        ProgressView()
          .padding()
        Spacer()
      }
      .listRowSeparator(.hidden)
    }
  }

  var loadingView: some View {
    ForEach(AraPost.mockList) { post in
      PostListRow(post: post)
        .listRowSeparator(.hidden, edges: .top)
        .listRowSeparator(.visible, edges: .bottom)
    }
  }
}

#Preview {
  NavigationStack {
    PostListView(board: AraBoard.mock)
  }
}



