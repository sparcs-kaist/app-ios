//
//  AraMyPostView.swift
//  soap
//
//  Created by 하정우 on 8/28/25.
//

import SwiftUI

struct AraMyPostView: View {
  @State private var vm: AraMyPostViewModelProtocol
  @State private var loadedInitialPosts: Bool = false
  
  init(user: AraUser?, type: AraMyPostViewModel.PostType = .all) {
    _vm = State(initialValue: AraMyPostViewModel(user: user, type: type))
  }
  
  var body: some View {
    switch vm.type {
    case .all:
      myPostView
    case .bookmark:
      bookmarkedPostView
    }
  }
  
  private var myPostView: some View {
    Group {
      if !vm.searchKeyword.isEmpty && vm.posts.isEmpty {
        ContentUnavailableView.search(text: vm.searchKeyword)
      } else {
        switch vm.state {
        case .loading:
          loadingView
        case .loaded:
          loadedView
        case .error(let message):
          ContentUnavailableView("Error", systemImage: "wifi.exclamationmark", description: Text(message))
        }
      }
    }
    .task {
      if !loadedInitialPosts {
        vm.bind()
        await vm.fetchInitialPosts()
        loadedInitialPosts = true
      }
    }
    .searchable(text: $vm.searchKeyword)
  }
  
  private var bookmarkedPostView: some View {
    Group {
      switch vm.state {
      case .loading:
        loadingView
      case .loaded:
        loadedView
      case .error(let message):
        ContentUnavailableView("Error", systemImage: "wifi.exclamationmark", description: Text(message))
      }
    }
    .task {
      await vm.fetchInitialPosts()
    }
  }
  
  private var loadingView: some View {
    PostList(posts: AraPost.mockList, destination: { _ in EmptyView()})
      .redacted(reason: .placeholder)
  }
  
  private var loadedView: some View {
    PostList(
      posts: vm.posts,
      destination: { post in
        PostView(post: post)
          .addKeyboardVisibilityToEnvironment()
          .onDisappear() {
            vm.refreshItem(postID: post.id)
          }
      },
      onRefresh: {
        await vm.fetchInitialPosts()
      },
      onLoadMore: {
        await vm.loadNextPage()
      }
    )
  }
}
