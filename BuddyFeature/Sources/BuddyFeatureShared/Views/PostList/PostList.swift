//
//  PostList.swift
//  soap
//
//  Created by Soongyu Kwon on 15/08/2025.
//

import Foundation
import SwiftUI
import BuddyDomain

public struct PostList: View {
  let posts: [AraPost]?
  var isLoadingMore: Bool = false
  var onRefresh: (() async -> Void)? = nil
  var onLoadMore: (() -> Void)? = nil

  public init(
    posts: [AraPost]?,
    isLoadingMore: Bool = false,
    onRefresh: (() async -> Void)? = nil,
    onLoadMore: (() -> Void)? = nil
  ) {
    self.posts = posts
    self.isLoadingMore = isLoadingMore
    self.onRefresh = onRefresh
    self.onLoadMore = onLoadMore
  }

  public var body: some View {
    if let posts, posts.isEmpty {
      ContentUnavailableView(
        "Nothing Here Yet",
        systemImage: "questionmark.text.page",
        description: Text(String(localized: "It looks like there are no posts on this page right now.", bundle: .module))
      )
    } else {
      List {
        if let posts {
          loadedView(posts)
        } else {
          loadingView
            .redacted(reason: .placeholder)
        }
      }
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
        .id(post.id)
        .selectionDisabled(post.isHidden)
        .listRowSeparator(.hidden, edges: .top)
        .listRowSeparator(.visible, edges: .bottom)
        .listRowBackground(Color.clear)
        .onAppear {
          // loads more contents on 60% scroll
          let thresholdIndex = Int(Double(posts.count) * Constants.loadMoreThreshold)
          if index >= thresholdIndex && !isLoadingMore {
            onLoadMore?()
          }
        }
        .background {
          if !post.isHidden {
            NavigationLink(value: post) {
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
        .listRowBackground(Color.clear)
    }
  }
}


#Preview("Loading") {
  PostList(posts: nil)
}

#Preview("Empty") {
  PostList(posts: [])
}

#Preview("Loaded") {
  NavigationStack {
    PostList(posts: AraPost.mockList)
      .navigationDestination(for: AraPost.self) { post in
        Text(String(localized: "Post \(post.id)", bundle: .module))
      }
  }
}
