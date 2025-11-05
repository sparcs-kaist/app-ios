//
//  BoardListView.swift
//  soap
//
//  Created by Soongyu Kwon on 03/06/2025.
//

import SwiftUI
import BuddyDomain

struct ListGlassSection<Content: View>: View {
  let header: Label<Text, Image>
  let content: () -> Content

  @Environment(\.colorScheme) private var colorScheme

  init(
    header: Label<Text, Image>,
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.header = header
    self.content = content
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        header
          .font(.title2)
          .fontWeight(.bold)
        Spacer()
      }

      VStack(alignment: .leading, spacing: 0) {
        content()
          .padding(.vertical)
      }
      .padding(.horizontal)
      .glassEffect(
        colorScheme == .light ? .identity : .regular.interactive(),
        in: .rect(cornerRadius: 28)
      )
      .background(colorScheme == .light ? Color.secondarySystemGroupedBackground : .clear, in: .rect(cornerRadius: 28))
    }
  }
}

struct BoardListView: View {
  @State private var viewModel: BoardListViewModelProtocol = BoardListViewModel()
  @State private var selectedBoard: AraBoard? = nil
  @State private var selectedPost: AraPost? = nil
  @State private var columnVisibility: NavigationSplitViewVisibility = .all
  @State private var preferredCompactColumn: NavigationSplitViewColumn = .sidebar
  @State private var tabBarVisibility: Visibility = .visible
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass

  init(_ viewModel: BoardListViewModelProtocol = BoardListViewModel()) {
    _viewModel = State(initialValue: viewModel)
  }
  
  var body: some View {
    NavigationSplitView(columnVisibility: $columnVisibility, preferredCompactColumn: $preferredCompactColumn, sidebar: {
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
            ContentUnavailableView("Error", systemImage: "wifi.exclamationmark", description: Text(message))
          }
        }
        .padding()
      }
      .background {
        BackgroundGradientView(color: .red)
          .ignoresSafeArea()
      }
      .background(Color.systemGroupedBackground)
      .disabled(viewModel.state == .loading)
      .navigationTitle(horizontalSizeClass == .compact ? String(localized: "Boards") : "")
      .toolbarTitleDisplayMode(.inlineLarge)
      .task {
        await viewModel.fetchBoards()
      }
      .toolbar(tabBarVisibility, for: .tabBar) // workaround for tabBar disappering inside NavigationSplitView
    }, content: {
      if let board = selectedBoard {
        PostListView(board: board, selectedPost: $selectedPost)
          .id(board.id)
      }
    }, detail: {
      if let post = selectedPost {
        PostView(post: post)
          .id(post.id)
      }
    })
    .onChange(of: columnVisibility) {
      if columnVisibility == .all {
        tabBarVisibility = .visible
      }
    }
    .onChange(of: preferredCompactColumn) {
      if preferredCompactColumn == .sidebar {
        tabBarVisibility = .visible
      }
    }
  }

  @ViewBuilder
  func loadedView(boards: [AraBoard], groups: [AraBoardGroup]) -> some View {
    ForEach(groups) { group in
      ListGlassSection(
        header: Label(group.name.localized(), systemImage: symbol(for: group.slug))
      ) {
        ForEach(boards.filter { $0.group.id == group.id }) { board in
          Button(action: {
            selectedBoard = board
            if horizontalSizeClass == .compact {
              preferredCompactColumn = .content
              tabBarVisibility = .hidden
            } else {
              columnVisibility = .doubleColumn
            }
          }, label: {
            HStack {
              Text(board.name.localized())
                .multilineTextAlignment(.leading)
              Spacer()
              Image(systemName: "chevron.right")
                .opacity(0.3)
            }
          })
          .tint(.primary)
          .id(board.id)
        }
      }
      .id(group.id)
    }
  }

  @ViewBuilder
  var loadingView: some View {
    ForEach(0..<5) { _ in
      ListGlassSection(header: Label("Notice", systemImage: "bell.badge.fill")) {
        ForEach(0..<3) { _ in
          NavigationLink(destination: {
          }, label: {
            HStack {
              Text("Portal Notice")
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
  @Previewable @State var viewModel = MockBoardListViewModel()
  viewModel.state = .loading
  
  return BoardListView(viewModel)
}

#Preview("Loaded State") {
  @Previewable @State var viewModel = MockBoardListViewModel()
  BoardListView(viewModel)
}

#Preview("Error State") {
  @Previewable @State var viewModel = MockBoardListViewModel()
  viewModel.state = .error(message: "Something went wrong")
  
  return BoardListView(viewModel)
}
