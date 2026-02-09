//
//  FeedView.swift
//  soap
//
//  Created by Soongyu Kwon on 17/08/2025.
//

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

  @State private var spoilerContents = SpoilerContents()

  @Environment(\.horizontalSizeClass) private var horizontalSizeClass

  public init(_ viewModel: FeedViewModelProtocol = FeedViewModel()) {
    self._viewModel = State(initialValue: viewModel)
  }

  public var body: some View {
    NavigationStack {
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
        .animation(.spring, value: viewModel.posts)
      }
      .disabled(viewModel.state == .loading)
      .navigationTitle(horizontalSizeClass == .compact ? String(localized: "Feed") : "")
      .toolbarTitleDisplayMode(.inlineLarge)
      .navigationDestination(for: String.self) { postID in
        if let index = viewModel.posts.firstIndex(where: { $0.id == postID }) {
          FeedPostView(post: $viewModel.posts[index], onDelete: {
            await viewModel.deletePost(postID: postID)
          })
          .environment(spoilerContents)
          .addKeyboardVisibilityToEnvironment()
        }
      }
      .task {
        await viewModel.fetchInitialData()
      }
      .refreshable {
        await viewModel.refreshFeed()
      }
      .toolbar {
        ToolbarItem {
          Button("Write", systemImage: "square.and.pencil") {
            viewModel.writeFeedButtonTapped()
            showComposeView = true
          }
        }

        ToolbarSpacer(.fixed)
        
        ToolbarItem {
          Button("Settings", systemImage: "gear") {
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
      .alert(viewModel.alertState?.title ?? "Error", isPresented: $viewModel.isAlertPresented, actions: {
        Button("Okay", role: .close) { }
      }, message: {
        Text(viewModel.alertState?.message ?? "Unexpected Error")
      })
      .background {
        BackgroundGradientView(color: .accentColor)
          .ignoresSafeArea()
      }
    }
    .analyticsScreen(name: "Feed", class: String(describing: Self.self))
  }

  private var contentView: some View {
    ForEach($viewModel.posts) { $post in
      NavigationLink(value: post.id) {
        FeedPostRow(post: $post, onPostDeleted: { postID in
          Task {
            await viewModel.deletePost(postID: postID)
          }
        }, onComment: nil)
        .environment(spoilerContents)
        .contentShape(.rect)
      }
      .id(post.id)
      .padding(.vertical)
      .navigationLinkIndicatorVisibility(.hidden)
      .buttonStyle(.plain)
      .matchedTransitionSource(id: post.id, in: namespace)

      Divider()
        .padding(.horizontal)
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
      "Error",
      systemImage: "questionmark.text.page",
      description: Text(message)
    )
  }

}


// MARK: - Previews

#Preview("Loading") {
  FeedView(PreviewFeedViewModel(state: .loading, posts: FeedPost.mockList))
}

#Preview("Loaded") {
  FeedView(PreviewFeedViewModel(state: .loaded, posts: FeedPost.mockList))
}

#Preview("Error") {
  FeedView(PreviewFeedViewModel(state: .error(message: "Something went wrong")))
}

#Preview("Empty") {
  FeedView(PreviewFeedViewModel(state: .loaded, posts: []))
}
