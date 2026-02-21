//
//  UserPostListView.swift
//  soap
//
//  Created by Soongyu Kwon on 16/08/2025.
//

import SwiftUI
import Observation
import BuddyDomain
import BuddyPreviewSupport
import FirebaseAnalytics
import BuddyFeatureShared

struct UserPostListView: View {
  @State private var viewModel: UserPostListViewModelProtocol

  @State private var loadedInitialPost: Bool = false
  @State private var searchText: String = ""
  @State private var selectedPost: AraPost?

  init(user: AraPostAuthor) {
    _viewModel = State(initialValue: UserPostListViewModel(user: user))
  }

  init(viewModel: UserPostListViewModelProtocol) {
    _viewModel = State(initialValue: viewModel)
  }

  var body: some View {
    Group {
      if !viewModel.searchKeyword.isEmpty && viewModel.posts.isEmpty {
        ContentUnavailableView.search(text: viewModel.searchKeyword)
      } else {
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
        case .error(let message):
          ContentUnavailableView("Error", systemImage: "wifi.exclamationmark", description: Text(message))
        }
      }
    }
    .disabled(viewModel.state == .loading)
    .navigationTitle(viewModel.user.profile.nickname)
    .toolbar(.hidden, for: .tabBar)
    .toolbar {
      DefaultToolbarItem(kind: .search, placement: .bottomBar)
    }
    .task {
      if !loadedInitialPost {
        viewModel.bind()
        await viewModel.fetchInitialPosts()
        loadedInitialPost = true
      }
    }
    .searchable(text: $viewModel.searchKeyword)
    .analyticsScreen(name: "Ara User Post List", class: String(describing: Self.self))
  }
}
#Preview("Loading State") {
  NavigationStack {
    UserPostListView(viewModel: PreviewUserPostListViewModel(
      state: .loading,
      user: .previewAuthor
    ))
  }
}

#Preview("Loaded State") {
  NavigationStack {
    UserPostListView(viewModel: PreviewUserPostListViewModel(
      state: .loaded(posts: AraPost.mockList),
      user: .previewAuthor,
      posts: AraPost.mockList
    ))
  }
}

#Preview("Error State") {
  NavigationStack {
    UserPostListView(viewModel: PreviewUserPostListViewModel(
      state: .error(message: "Something went wrong"),
      user: .previewAuthor
    ))
  }
}

#Preview("Empty Search") {
  NavigationStack {
    UserPostListView(viewModel: PreviewUserPostListViewModel(
      state: .loaded(posts: []),
      user: .previewAuthor,
      posts: [],
      searchKeyword: "no results"
    ))
  }
}


