//
//  PostList.swift
//  soap
//
//  Created by Soongyu Kwon on 15/08/2025.
//

import SwiftUI
import BuddyDomain
import BuddyDataMocks

struct PostList<Destination: View>: View {
  let posts: [AraPost]?
  @ViewBuilder let destination: (AraPost) -> Destination
  var onRefresh: (() async -> Void)? = nil
  var onLoadMore: (() async -> Void)? = nil

  @State private var isLoadingMore: Bool = false

  var body: some View {
    if let posts, posts.isEmpty {
      ContentUnavailableView(
        "Nothing Here Yet",
        systemImage: "questionmark.text.page",
        description: Text("It looks like there are no posts on this page right now.")
      )
    } else {
      List {
        if posts == nil {
          loadingView
            .redacted(reason: .placeholder)
        } else if let posts {
          loadedView(posts)
        }
      }
      .scrollContentBackground(.hidden)
      .listStyle(.plain)
      .refreshable {
        await onRefresh?()
      }
    }
  }

  @ViewBuilder
  func loadedView(_ posts: [AraPost]) -> some View {
    ForEach(Array(posts.enumerated()), id: \.element.id) { index, post in
      PostListRow(post: post)
        .tag(post)
        .selectionDisabled(post.isHidden)
        .listRowSeparator(.hidden, edges: .top)
        .listRowSeparator(.visible, edges: .bottom)
        .onAppear {
          // loads more contents on 60% scroll
          let thresholdIndex = Int(Double(posts.count) * Constants.loadMoreThreshold)
          if index >= thresholdIndex {
            Task {
              isLoadingMore = true
              await onLoadMore?()
              isLoadingMore = false
            }
          }
        }
        .background {
          if !post.isHidden {
            NavigationLink {
              destination(post)
            } label: {
              EmptyView()
            }
            .opacity(0)
          }
        }
    }

    if isLoadingMore {
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


#Preview("Loading") {
  PostList(posts: nil, destination: { _ in
    EmptyView()
  })
}

#Preview("Empty") {
  PostList(posts: [], destination: { _ in
    EmptyView()
  })
}

#Preview("Loaded") {
  PostList(posts: AraPost.mockList, destination: { post in
    PostView(post: post)
      .id(post.id)
  })
}
