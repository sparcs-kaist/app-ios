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
  /// The sections as saved in Settings, watched so the list follows a change made there.
  @AppStorage(BoardListSectionStore.key) private var savedSections: Data?

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
    .onChange(of: savedSections) {
      viewModel.reloadSections()
    }
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
    ForEach(viewModel.sections) { section in
      self.section(section, boards: boards)
    }
    ForEach(groups) { group in
      ListGlassSection(
        header: Label(group.name.localized(), systemImage: group.symbolName)
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

  /// One of the reader's sections. A board's posts preview as a list, Market's as a shelf; a
  /// board that's gone or can't be read is left out.
  @ViewBuilder
  private func section(_ section: BoardListSection, boards: [AraBoard]) -> some View {
    let posts = viewModel.posts(for: section)
    switch section {
    case .trending:
      highlight(.trending, posts: posts)
    case .latest:
      highlight(.latest(boardIDs: BoardListViewModel.latestBoardIDs(in: boards)), posts: posts)
    case .board(let slug):
      if let board = boards.first(where: { $0.slug == slug && $0.userReadable != false }) {
        if board.isMarket {
          marketShelf(board, posts: posts)
        } else {
          highlight(.board(board), posts: posts)
        }
      }
    }
  }

  /// A highlight section, as a placeholder while its posts load and hidden if there are none.
  @ViewBuilder
  private func highlight(_ highlight: BoardHighlight, posts: [AraPost]?) -> some View {
    if let posts {
      if !posts.isEmpty {
        HighlightSection(highlight: highlight, posts: posts) { selectedHighlightPost = $0 }
      }
    } else {
      HighlightSection(highlight: highlight, posts: Self.placeholderPosts(count: 3)) { _ in }
        .redacted(reason: .placeholder)
        .disabled(true)
    }
  }

  @ViewBuilder
  private func marketShelf(_ board: AraBoard, posts: [AraPost]?) -> some View {
    if let posts {
      if !posts.isEmpty {
        MarketShelf(board: board, posts: posts) { selectedHighlightPost = $0 }
      }
    } else {
      MarketShelf(board: board, posts: Self.placeholderPosts(count: 4)) { _ in }
        .redacted(reason: .placeholder)
        .disabled(true)
    }
  }

  /// Stand-ins shaped like real posts (the mocks have distinct ids).
  private static func placeholderPosts(count: Int) -> [AraPost] {
    let mocks = AraPost.mockList
    return (0..<count).map { mocks[$0 % mocks.count] }
  }

  @ViewBuilder
  var loadingView: some View {
    ForEach(viewModel.sections) { section in
      switch section {
      case .trending: highlight(.trending, posts: nil)
      case .latest: highlight(.latest(boardIDs: []), posts: nil)
      case .board(AraBoard.marketSlug): marketShelf(.mock, posts: nil)
      case .board: highlight(.board(.mock), posts: nil)
      }
    }
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


