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
  @State private var layout = FeedLayout()
  /// The selected post drives both manual and adaptive detail navigation.
  @State private var detailPostID: String? = nil
  /// The top-most visible post, kept in view when the feed column resizes.
  @State private var scrolledPostID: String? = nil

  @State private var spoilerContents = SpoilerContents()

  @Environment(\.layoutDirection) private var layoutDirection

  public init(_ viewModel: FeedViewModelProtocol = FeedViewModel()) {
    self._viewModel = State(initialValue: viewModel)
  }

  private var availableCommentsWidth: CGFloat {
    max(0, layout.width - ContentLayout.maxContentWidth)
  }

  private var commentsPanelWidth: CGFloat {
    if let split = layout.foldSplit {
      return max(0, layout.width - split.leadingWidth - split.gutter)
    }
    return min(Constants.feedCommentsPanelMaximumWidth, availableCommentsWidth)
  }

  private var canShowCommentsPanel: Bool {
    if layout.hasDivision {
      // A horizontal division (inner portrait display) cannot support columns.
      return layout.foldSplit != nil
    }
    return availableCommentsWidth >= Constants.feedCommentsPanelMinimumWidth
  }

  private var isCommentsPanelVisible: Bool {
    canShowCommentsPanel && commentsPostID != nil
  }

  public var body: some View {
    HStack(spacing: isCommentsPanelVisible ? layout.foldSplit?.gutter ?? 0 : 0) {
      feedList
        .frame(width: isCommentsPanelVisible ? layout.foldSplit?.leadingWidth : nil)

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
        .frame(width: commentsPanelWidth)
        .overlay(alignment: .leading) {
          Divider()
            .ignoresSafeArea()
            .offset(x: (layout.foldSplit?.gutter ?? 0) / 2 * (layoutDirection == .leftToRight ? -1 : 1))
        }
        .transition(.move(edge: .trailing))
      }
    }
    .feedLayout($layout)
    .onChange(of: canShowCommentsPanel) { _, isAvailable in
      withAnimation(.spring) {
        if isAvailable, let postID = detailPostID {
          scrolledPostID = postID
          commentsPostID = postID
          detailPostID = nil
        } else if !isAvailable, detailPostID == nil, let postID = commentsPostID {
          commentsPostID = nil
          detailPostID = postID
        }
      }
    }
    .animation(.spring, value: isCommentsPanelVisible)
    .navigationTitle(Text("Feed", bundle: .module))
    .toolbarTitleDisplayMode(.inlineLarge)
    .navigationDestination(item: $detailPostID) { postID in
      postDestination(postID: postID)
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

  @ViewBuilder
  private func postDestination(postID: String) -> some View {
    if let index = viewModel.posts.firstIndex(where: { $0.id == postID }) {
      FeedPostView(post: $viewModel.posts[index], onDelete: {
        await viewModel.deletePost(postID: postID)
      })
      .feedLayout($layout)
      .environment(spoilerContents)
    }
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
        Button {
          detailPostID = post.id
        } label: {
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


private nonisolated struct FeedLayout: Equatable, Sendable {
  var width: CGFloat = 0
  var foldSplit: FoldSplit? = nil
  var hasDivision = false
}

/// Installed on both the feed and its detail, which can cover the feed
/// while the active display changes.
private struct FeedLayoutObserver: ViewModifier {
  @Binding var layout: FeedLayout

  func body(content: Content) -> some View {
    content
      .onGeometryChange(for: FeedLayout.self) { geometry in
        if #available(iOS 27.1, *) {
          return FeedLayout(
            width: geometry.size.width,
            foldSplit: FoldSplit(proxy: geometry, includeInactive: true),
            hasDivision: !geometry.reservedRegions(kind: .division, options: .includeInactive).isEmpty
          )
        }
        return FeedLayout(width: geometry.size.width)
      } action: { layout in
        self.layout = layout
      }
  }
}

private extension View {
  func feedLayout(_ layout: Binding<FeedLayout>) -> some View {
    modifier(FeedLayoutObserver(layout: layout))
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
