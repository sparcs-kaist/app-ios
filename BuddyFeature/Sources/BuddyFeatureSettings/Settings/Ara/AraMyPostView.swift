//
//  AraMyPostView.swift
//  soap
//
//  Created by 하정우 on 8/28/25.
//

import Foundation
import SwiftUI
import BuddyDomain
import BuddyPreviewSupport
import FirebaseAnalytics
import BuddyFeatureShared
import BuddyFeaturePost

struct AraMyPostView: View {
  @State private var vm: AraMyPostViewModelProtocol
  @State private var loadedInitialPosts: Bool = false
  @State private var selectedPost: AraPost?
  
  init(type: AraMyPostType = .all) {
    _vm = State(initialValue: AraMyPostViewModel(type: type))
  }

  init(vm: AraMyPostViewModelProtocol) {
    _vm = State(initialValue: vm)
    _loadedInitialPosts = State(initialValue: true)
  }
  
  var body: some View {
    Group {
      switch vm.type {
      case .all:
        myPostView
      case .bookmark:
        bookmarkedPostView
      }
    }
    .disabled(!isLoaded)
    .analyticsScreen(name: "Ara My Post", class: String(describing: Self.self))
  }
  
  private var myPostView: some View {
    Group {
      switch vm.state {
      case .loading:
        loadingView
      case .loaded:
        if !vm.searchKeyword.isEmpty && vm.posts.isEmpty {
          ContentUnavailableView.search(text: vm.searchKeyword)
        } else {
          loadedView
        }
      case .error(let message):
        ContentUnavailableView(String(localized: "Error", bundle: .module), systemImage: "wifi.exclamationmark", description: Text(message))
      }
    }
    .transition(.opacity.animation(.easeInOut(duration: 0.3)))
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
        ContentUnavailableView(String(localized: "Error", bundle: .module), systemImage: "wifi.exclamationmark", description: Text(message))
      }
    }
    .task {
      if !loadedInitialPosts {
        await vm.fetchInitialPosts()
        loadedInitialPosts = true
      }
    }
  }
  
  private var loadingView: some View {
    PostList(posts: AraPost.mockList)
      .redacted(reason: .placeholder)
  }
  
  private var loadedView: some View {
    PostList(
      posts: vm.posts,
      isLoadingMore: vm.isLoadingMore,
      onRefresh: {
        await vm.fetchInitialPosts()
      },
      onLoadMore: {
        Task { await vm.loadNextPage() }
      }
    )
    .navigationDestination(for: AraPost.self) { post in
      PostView(post: post)
        .addKeyboardVisibilityToEnvironment()
        .onDisappear {
          vm.refreshItem(postID: post.id)
        }
    }
  }

  private var isLoaded: Bool {
    if case .loaded = vm.state {
      return true
    }
    return false
  }
}

#Preview("My Posts") {
  NavigationStack {
    AraMyPostView(vm: PreviewAraMyPostViewModel(type: .all))
      .navigationTitle(String(localized: "My Posts", bundle: .module))
      .navigationBarTitleDisplayMode(.inline)
  }
}

#Preview("Bookmarked Posts") {
  NavigationStack {
    AraMyPostView(vm: PreviewAraMyPostViewModel(type: .bookmark))
      .navigationTitle(String(localized: "Bookmarked Posts", bundle: .module))
      .navigationBarTitleDisplayMode(.inline)
  }
}

#Preview("Loading State") {
  NavigationStack {
    AraMyPostView(vm: PreviewAraMyPostViewModel(type: .all, state: .loading))
  }
}

#Preview("Error State") {
  NavigationStack {
    AraMyPostView(vm: PreviewAraMyPostViewModel(type: .all, state: .error(message: "Network error")))
  }
}
