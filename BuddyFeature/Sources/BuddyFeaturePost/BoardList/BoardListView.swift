//
//  BoardListView.swift
//  soap
//
//  Created by Soongyu Kwon on 03/06/2025.
//

import Foundation
import SwiftUI
import BuddyDomain
import BuddyFeatureShared
import BuddyPreviewSupport
import FirebaseAnalytics

public struct BoardListView: View {
  @State private var viewModel: BoardListViewModelProtocol = BoardListViewModel()
  @Binding var deepLinkedPost: AraPost?
  @State private var selectedHighlightPost: AraPost?

  public init(_ viewModel: BoardListViewModelProtocol = BoardListViewModel(), deepLinkedPost: Binding<AraPost?> = .constant(nil)) {
    _viewModel = State(initialValue: viewModel)
    _deepLinkedPost = deepLinkedPost
  }

  public var body: some View {
    ScrollView {
      LazyVStack(spacing: 20) {
        switch viewModel.state {
        case .loading:
          loadingView
            .redacted(reason: .placeholder)
            .disabled(true)
        case .loaded(let boards, let groups):
          loadedView(boards: boards, groups: groups)
        case .error(let message):
          ContentUnavailableView(String(localized: "Error", bundle: .module), systemImage: "wifi.exclamationmark", description: Text(message))
        }
      }
      .padding()
      .contentWidth()
    }
    .background {
      BackgroundGradientView(color: .red)
        .ignoresSafeArea()
    }
    .background(Color.systemGroupedBackground)
    .disabled(viewModel.state == .loading)
    .navigationTitle(String(localized: "Boards", bundle: .module))
    .toolbarTitleDisplayMode(.inlineLarge)
    .navigationDestination(for: AraBoard.self) { board in
      PostListView(board: board)
        .id(board.id)
    }
    // By item rather than value: PostListView declares its own AraPost destination further up the stack.
    .navigationDestination(item: $selectedHighlightPost) { post in
      PostView(post: post)
        .addKeyboardVisibilityToEnvironment()
        .toolbar(.hidden, for: .tabBar)
    }
    .navigationDestination(item: $deepLinkedPost) { post in
      PostView(post: post)
        .toolbar(.hidden, for: .tabBar)
    }
    .analyticsScreen(name: "Board List", class: String(describing: Self.self))
    .task {
      await viewModel.fetchBoards()
    }
  }

  @ViewBuilder
  func loadedView(boards: [AraBoard], groups: [AraBoardGroup]) -> some View {
    let boardsByGroup = Dictionary(grouping: boards, by: { $0.group.id })
    if !viewModel.trendingPosts.isEmpty {
      HighlightSection(highlight: .trending, posts: viewModel.trendingPosts) { selectedHighlightPost = $0 }
    }
    if !viewModel.latestPosts.isEmpty {
      HighlightSection(
        highlight: .latest(boardIDs: BoardListViewModel.latestBoardIDs(in: boards)),
        posts: viewModel.latestPosts
      ) { selectedHighlightPost = $0 }
    }
    ForEach(groups) { group in
      ListGlassSection(
        header: Label(group.name.localized(), systemImage: symbol(for: group.slug))
      ) {
        ForEach(boardsByGroup[group.id] ?? []) { board in
          NavigationLink(value: board) {
            HStack {
              Text(board.name.localized())
                .multilineTextAlignment(.leading)
              Spacer()
              if viewModel.boardsWithNewPosts.contains(board.id) {
                Circle()
                  .fill(Color.accentColor)
                  .frame(width: 8, height: 8)
                  .accessibilityLabel(Text("New Posts", bundle: .module))
                  .transition(.scale.combined(with: .opacity))
              }
              Image(systemName: "chevron.right")
                .opacity(0.3)
            }
          }
          .tint(.primary)
        }
      }
      .id(group.id)
    }
    .animation(.snappy, value: viewModel.boardsWithNewPosts)
  }

  @ViewBuilder
  var loadingView: some View {
    ForEach(0..<5) { _ in
      ListGlassSection(header: Label(String(localized: "Notice", bundle: .module), systemImage: "bell.badge.fill")) {
        ForEach(0..<3) { _ in
          NavigationLink(destination: {
          }, label: {
            HStack {
              Text("Portal Notice", bundle: .module)
              Spacer()
              Image(systemName: "chevron.right")
                .opacity(0.3)
            }
          })
          .tint(.primary)
        }
      }
    }
  }

  func symbol(for slug: String) -> String {
    switch slug {
    case "notice":
      "bell.badge.fill"
    case "talk":
      "text.bubble.fill"
    case "club":
      "person.2.fill"
    case "trade":
      "tag.fill"
    case "communication":
      "envelope.open.fill"
    default:
      "list.clipboard"
    }
  }
}


#Preview("Loading State") {
  BoardListView(PreviewBoardListViewModel(state: .loading))
}

#Preview("Loaded State") {
  BoardListView(PreviewBoardListViewModel(state: PreviewBoardListViewModel.loadedState()))
}

#Preview("Error State") {
  BoardListView(PreviewBoardListViewModel(state: .error(message: "Something went wrong")))
}


