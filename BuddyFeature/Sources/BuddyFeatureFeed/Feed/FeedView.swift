//
//  FeedView.swift
//  soap
//
//  Created by Soongyu Kwon on 17/08/2025.
//

import Foundation
import SwiftUI
import BuddyDomain
import BuddyFeatureShared
import BuddyFeatureSettings
import BuddyPreviewSupport
import FirebaseAnalytics

public struct FeedView: View {
  @State private var viewModel: FeedViewModelProtocol = FeedViewModel()
  @Namespace private var namespace

  @State private var showSettingsSheet: Bool = false
  @State private var showComposeView: Bool = false
  /// The post whose comments are shown beside the feed on wide layouts.
  @State private var commentsPostID: String? = nil
  @State private var availableWidth: CGFloat = 0
  /// The top-most visible post, kept in view when the feed column resizes.
  @State private var scrolledPostID: String? = nil

  @State private var spoilerContents = SpoilerContents()

  public init(_ viewModel: FeedViewModelProtocol = FeedViewModel()) {
    self._viewModel = State(initialValue: viewModel)
  }

  /// Width from which comments open in a column beside the feed instead of on
  /// the post page. Decided by the actual width rather than the size class so
  /// that roomy compact screens, like the inner display of a foldable iPhone,
  /// get the column too.
  private static let commentsPanelMinimumWidth: CGFloat = 640

  private var canShowCommentsPanel: Bool {
    availableWidth >= Self.commentsPanelMinimumWidth
  }

  public var body: some View {
    HStack(spacing: 0) {
      feedList

      if canShowCommentsPanel, let commentsPostID,
         let index = viewModel.posts.firstIndex(where: { $0.id == commentsPostID }) {
        // The column slides in and out as a whole; switching posts swaps only
        // its contents, so old and new panels never sit side by side. The
        // divider rides along on its leading edge so it never lands on the feed
        // before the feed has finished narrowing.
        ZStack {
          FeedCommentsPanel(post: $viewModel.posts[index], onClose: { self.commentsPostID = nil })
            .id(commentsPostID)
        }
        .frame(width: min(400, availableWidth * 0.45))
        .overlay(alignment: .leading) {
          Divider()
            .ignoresSafeArea()
        }
        .transition(.move(edge: .trailing))
      }
    }
    .animation(.spring, value: commentsPostID != nil)
    .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width in
      availableWidth = width
      if !canShowCommentsPanel { commentsPostID = nil }
    }
    .navigationTitle(Text("Feed", bundle: .module))
    .toolbarTitleDisplayMode(.inlineLarge)
    .navigationDestination(for: String.self) { postID in
      if let index = viewModel.posts.firstIndex(where: { $0.id == postID }) {
        FeedPostView(post: $viewModel.posts[index], onDelete: {
          await viewModel.deletePost(postID: postID)
        })
        .environment(spoilerContents)
      }
    }
    .task {
      guard viewModel.state == .loading else { return }
      await viewModel.fetchInitialData()
    }
    .toolbar {
      ToolbarItem {
        Button(String(localized: "Write", bundle: .module), systemImage: "square.and.pencil") {
          viewModel.writeFeedButtonTapped()
          showComposeView = true
        }
      }
      .keptOutOfOverflow()
      .matchedTransitionSource(id: "ComposeView", in: namespace)

      ToolbarSpacer(.fixed)

      ToolbarItem {
        Button(String(localized: "Settings", bundle: .module), systemImage: "gear") {
          viewModel.openSettingsTapped()
          showSettingsSheet = true
        }
      }
    }
    .sheet(isPresented: $showSettingsSheet) {
      SettingsView()
        .presentationDragIndicator(.visible)
    }
    .sheet(isPresented: $showComposeView, onDismiss: {
      Task {
        await viewModel.fetchInitialData()
      }
    }) {
      FeedPostComposeView()
        .navigationTransition(.zoom(sourceID: "ComposeView", in: namespace))
        .interactiveDismissDisabled()
    }
    .alert(viewModel.alertState?.title ?? String(localized: "Error", bundle: .module), isPresented: $viewModel.isAlertPresented, actions: {
      Button(String(localized: "Okay", bundle: .module), role: .close) { }
    }, message: {
      Text(viewModel.alertState?.message ?? String(localized: "Unexpected Error", bundle: .module))
    })
    .background {
      BackgroundGradientView(color: .accentColor)
        .ignoresSafeArea()
    }
    .analyticsScreen(name: "Feed", class: String(describing: Self.self))
  }

  private var feedList: some View {
    ScrollView {
      LazyVStack(spacing: 0) {
        switch viewModel.state {
        case .loading:
          loadingView
        case .loaded:
          contentView
        case .error(let message):
          errorView(message: message)
        }
      }
      .scrollTargetLayout()
      .animation(.spring, value: viewModel.posts.map(\.id))
      .contentWidth()
    }
    // Rows reflow when the comments column narrows the feed; anchoring on the
    // top-most post keeps it in place instead of jumping by the height change.
    .scrollPosition(id: $scrolledPostID, anchor: .top)
    .disabled(viewModel.state == .loading)
    .refreshable {
      await viewModel.refreshFeed()
    }
  }

  @ViewBuilder
  private var contentView: some View {
    ForEach($viewModel.posts) { $post in
      VStack(spacing: 0) {
        NavigationLink(value: post.id) {
          FeedPostRow(post: $post, onPostDeleted: { postID in
            if commentsPostID == postID { commentsPostID = nil }
            Task {
              await viewModel.deletePost(postID: postID)
            }
          }, onComment: canShowCommentsPanel ? {
            commentsPostID = commentsPostID == post.id ? nil : post.id
          } : nil)
          .environment(spoilerContents)
          .contentShape(.rect)
        }
        .padding(.vertical)
        .navigationLinkIndicatorVisibility(.hidden)
        .buttonStyle(.plain)
        .onAppear {
          let index = viewModel.posts.firstIndex(where: { $0.id == post.id }) ?? 0
          let threshold = Int(Double(viewModel.posts.count) * 0.6)
          if index >= threshold {
            Task { await viewModel.loadNextPage() }
          }
        }

        Divider()
          .padding(.horizontal)
      }
      .id(post.id)
    }

    if viewModel.isLoadingMore {
      ProgressView()
        .padding()
    }
  }

  private var loadingView: some View {
    ForEach(.constant(FeedPost.mockList)) { $post in
      FeedPostRow(post: $post, onPostDeleted: nil, onComment: nil)
        .environment(spoilerContents)
        .padding(.vertical)

      Divider()
        .padding(.horizontal)
    }
    .redacted(reason: .placeholder)
  }

  private func errorView(message: String) -> some View {
    ContentUnavailableView(
      String(localized: "Error", bundle: .module),
      systemImage: "questionmark.text.page",
      description: Text(message)
    )
  }

}

private extension ToolbarContent {
  /// Keeps Write in the bar when a short, vertical bar (the outer display of
  /// iPhone Duo in landscape) runs out of room and folds items into its
  /// overflow menu. `visibilityPriority` is iOS 27.0; earlier systems have no
  /// such overflow.
  @MainActor @ToolbarContentBuilder
  func keptOutOfOverflow() -> some ToolbarContent {
    if #available(iOS 27.0, *) {
      visibilityPriority(.high)
    } else {
      self
    }
  }
}


// MARK: - Previews

#Preview("Loading") {
  NavigationStack {
    FeedView(PreviewFeedViewModel(state: .loading, posts: FeedPost.mockList))
  }
}

#Preview("Loaded") {
  NavigationStack {
    FeedView(PreviewFeedViewModel(state: .loaded, posts: FeedPost.mockList))
  }
}

#Preview("Error") {
  NavigationStack {
    FeedView(PreviewFeedViewModel(state: .error(message: "Something went wrong")))
  }
}

#Preview("Empty") {
  NavigationStack {
    FeedView(PreviewFeedViewModel(state: .loaded, posts: []))
  }
}
