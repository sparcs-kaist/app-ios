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
        description: Text("It looks like there are no posts on this page right now.", bundle: .module)
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
      row(for: post)
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

  /// The row plus whatever makes it navigate on this platform.
  @ViewBuilder
  private func row(for post: AraPost) -> some View {
    #if os(macOS)
    // UIKit's List promotes a hidden NavigationLink sitting in a row's background
    // into a tappable row; AppKit's does not, so the iOS pattern below leaves every
    // post dead on macOS — an `EmptyView` at `opacity(0)` has nothing to click.
    // Wrapping the row in a real link restores it. `.buttonStyle(.plain)` stops
    // AppKit painting a push-button capsule over the row and `macOSPlainHitArea()`
    // gives the stripped-down button a surface to hit-test again.
    if post.isHidden {
      PostListRow(post: post)
    } else {
      NavigationLink(value: post) {
        PostListRow(post: post)
          .macOSPlainHitArea()
      }
      .buttonStyle(.plain)
    }
    #else
    PostListRow(post: post)
      .background {
        if !post.isHidden {
          NavigationLink(value: post) {
            EmptyView()
          }
          .opacity(0)
        }
      }
    #endif
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
        Text("Post \(post.id)", bundle: .module)
      }
  }
}
