//
//  PostListView.swift
//  soap
//
//  Created by Soongyu Kwon on 05/01/2025.
//

import SwiftUI
import BuddyDomain
import BuddyFeatureShared

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
          destination: { _ in
            EmptyView()
          }
        )
      case .loaded(let posts):
        if viewModel.posts.isEmpty && !viewModel.searchKeyword.isEmpty {
          ContentUnavailableView.search(text: viewModel.searchKeyword)
        } else {
          PostList(
            posts: posts,
            destination: { post in
              PostView(post: post)
                .id(post.id)
                .addKeyboardVisibilityToEnvironment() // TODO: This should be changed to @FocusState, but it's somehow doesn't work with .safeAreaBar in the early stage of iOS 26.
                .onDisappear {
                  viewModel.refreshItem(postID: post.id)
                }
            }, onRefresh: {
              await viewModel.fetchInitialPosts()
            }, onLoadMore: {
              await viewModel.loadNextPage()
            }
          )
        }
      case .error(let message):
        ContentUnavailableView("Error", systemImage: "wifi.exclamationmark", description: Text(message))
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
    .background {
      BackgroundGradientView(color: .red)
        .ignoresSafeArea()
    }
    .scrollContentBackground(.hidden)
  }
}

//#Preview("Loading State") {
//  @Previewable @State var viewModel = MockPostListViewModel()
//  viewModel.state = .loading
//  
//  return NavigationStack {
//    PostListView(viewModel: viewModel)
//  }
//}
//
//#Preview("Loaded State") {
//  @Previewable @State var viewModel = MockPostListViewModel()
//  return NavigationStack {
//    PostListView(viewModel: viewModel)
//  }
//}
//
//#Preview("Error State") {
//  @Previewable @State var viewModel = MockPostListViewModel()
//  viewModel.state = .error(message: "Something went wrong")
//  
//  return NavigationStack {
//    PostListView(viewModel: viewModel)
//  }
//}
