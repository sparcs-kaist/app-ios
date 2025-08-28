//
//  AraMyPostView.swift
//  soap
//
//  Created by 하정우 on 8/28/25.
//

import SwiftUI

struct AraMyPostView: View {
  @Binding var vm: AraSettingsViewModelProtocol
  @State private var postType: AraSettingsViewModel.PostType = .all
  
  var body: some View {
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
    Group {
      Picker("Post Type", selection: $postType) {
        ForEach(AraSettingsViewModel.PostType.allCases, id: \.self) {
          Text($0.rawValue)
        }
      }
      .pickerStyle(.segmented)
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
}

#Preview("Loading State") {
  let vm = MockAraSettingsViewModel()
  vm.state = .loading
  
  return NavigationStack {
    AraMyPostView(vm: .constant(vm))
  }
}

#Preview("Loaded State") {
  let vm = MockAraSettingsViewModel()
  vm.state = .loaded
  vm.araNickname = "오열하는 운영체제 및 실험"
  vm.araAllowNSFWPosts = false
  vm.araAllowPoliticalPosts = true
  
  return NavigationStack {
    AraMyPostView(vm: .constant(vm))
  }
}

#Preview("Error State") {
  let vm = MockAraSettingsViewModel()
  vm.state = .error(message: "Network error")
  
  return NavigationStack {
    AraMyPostView(vm: .constant(vm))
  }
}
