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
  @Binding private var path: NavigationPath
  @Namespace private var namespace

  @State private var showSettingsSheet: Bool = false
  @State private var showComposeView: Bool = false
  @State private var scrolledPostID: String? = nil

  @State private var spoilerContents = SpoilerContents()
  @State private var imageAspects = FeedImageAspects()
  @State private var columnWidth: CGFloat = 0

  public init(_ viewModel: FeedViewModelProtocol = FeedViewModel(), path: Binding<NavigationPath>) {
    self._viewModel = State(initialValue: viewModel)
    self._path = path
  }

  public var body: some View {
    feedList
      .navigationTitle(Text("Feed", bundle: .module))
      .toolbarTitleDisplayMode(.inlineLarge)
      .navigationDestination(for: String.self) { postID in
        postDestination(postID: postID)
      }
      .onChange(of: viewModel.posts.map(\.id), initial: true) {
        imageAspects.prefetch(viewModel.posts)
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
    if let post = postBinding(id: postID) {
      FeedPostView(post: post, onDelete: {
        await viewModel.deletePost(postID: postID)
      })
      .environment(spoilerContents)
      .environment(imageAspects)
    }
  }

  /// Resolve by ID so a refresh or deletion cannot redirect a detail's writes
  /// to a different row.
  private func postBinding(id: String) -> Binding<FeedPost>? {
    guard let post = viewModel.posts.first(where: { $0.id == id }) else { return nil }
    return Binding(
      get: { viewModel.posts.first(where: { $0.id == id }) ?? post },
      set: { newValue in
        guard let index = viewModel.posts.firstIndex(where: { $0.id == id }) else { return }
        viewModel.posts[index] = newValue
      }
    )
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
      .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { columnWidth = $0 }
      .environment(\.feedColumnWidth, columnWidth)
      .environment(imageAspects)
      .contentWidth()
    }
    // Keep the visible post anchored when rows reflow after a resize.
    .scrollPosition(id: $scrolledPostID, anchor: .top)
    .disabled(viewModel.state == .loading)
    .refreshable {
      await viewModel.refreshFeed()
      // The scroll position would otherwise hold on to the post that was on
      // top, hiding any new posts above it.
      scrolledPostID = viewModel.posts.first?.id
    }
  }

  @ViewBuilder
  private var contentView: some View {
    ForEach($viewModel.posts) { $post in
      VStack(spacing: 0) {
        Button {
          path.append(post.id)
        } label: {
          FeedPostRow(post: $post, onPostDeleted: { postID in
            Task {
              await viewModel.deletePost(postID: postID)
            }
          }, onComment: nil)
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


// MARK: - Previews

#Preview("Loading") {
  @Previewable @State var path = NavigationPath()
  NavigationStack(path: $path) {
    FeedView(PreviewFeedViewModel(state: .loading, posts: FeedPost.mockList), path: $path)
  }
}

#Preview("Loaded") {
  @Previewable @State var path = NavigationPath()
  NavigationStack(path: $path) {
    FeedView(PreviewFeedViewModel(state: .loaded, posts: FeedPost.mockList), path: $path)
  }
}

#Preview("Error") {
  @Previewable @State var path = NavigationPath()
  NavigationStack(path: $path) {
    FeedView(PreviewFeedViewModel(state: .error(message: "Something went wrong")), path: $path)
  }
}

#Preview("Empty") {
  @Previewable @State var path = NavigationPath()
  NavigationStack(path: $path) {
    FeedView(PreviewFeedViewModel(state: .loaded, posts: []), path: $path)
  }
}
