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
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass

  init(_ viewModel: BoardListViewModelProtocol = BoardListViewModel()) {
    _viewModel = State(initialValue: viewModel)
  }
  
  var body: some View {
    NavigationSplitView(sidebar: {
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
        if horizontalSizeClass == .compact {
          BackgroundGradientView(color: .red)
            .ignoresSafeArea()
        }
      }
      .background(Color.systemGroupedBackground)
      .disabled(viewModel.state == .loading)
      .navigationTitle(horizontalSizeClass == .compact ? String(localized: "Boards") : "")
      .toolbarTitleDisplayMode(.inlineLarge)
      .toolbar(horizontalSizeClass == .compact ? .automatic : .visible, for: .tabBar) // workaround for tabBar disappering inside NavigationSplitView
    }, detail: {
      NavigationStack {
        
      }
      .background {
        BackgroundGradientView(color: .red)
          .ignoresSafeArea()
      }
    })
    .task {
      await viewModel.fetchBoards()
    }
    .ignoresSafeArea()
  }

  @ViewBuilder
  func loadedView(boards: [AraBoard], groups: [AraBoardGroup]) -> some View {
    ForEach(groups) { group in
      ListGlassSection(
        header: Label(group.name.localized(), systemImage: symbol(for: group.slug))
      ) {
        ForEach(boards.filter { $0.group.id == group.id }) { board in
          NavigationLink(destination: {
            PostListView(board: board)
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
