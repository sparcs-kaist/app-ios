//
//  UserPostListView.swift
//  soap
//
//  Created by Soongyu Kwon on 16/08/2025.
//

import SwiftUI

struct UserPostListView: View {
  @State private var viewModel: UserPostListViewModelProtocol

  @State private var loadedInitialPost: Bool = false
  @State private var searchText: String = ""

  init(user: AraPostAuthor) {
    _viewModel = State(initialValue: UserPostListViewModel(user: user))
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
  }
}
