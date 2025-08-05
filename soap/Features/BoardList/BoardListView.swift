//
//  BoardListView.swift
//  soap
//
//  Created by Soongyu Kwon on 03/06/2025.
//

import SwiftUI

struct BoardListView: View {
  @State private var viewModel = BoardListViewModel()

  var body: some View {
    NavigationStack {
      List {
        switch viewModel.state {
        case .loading:
          ProgressView()
        case .loaded(let boards, let groups):
          loadedView(boards: boards, groups: groups)
        case .error(let message):
          ContentUnavailableView("Error", systemImage: "wifi.exclamationmark", description: Text(message))
        }
      }
      .listStyle(.sidebar)
      .navigationTitle("Boards")
      .task {
        await viewModel.fetchBoards()
      }
    }
  }

  @ViewBuilder
  func loadedView(boards: [AraBoard], groups: [AraBoardGroup]) -> some View {
    ForEach(groups) { group in
      Section(header: Label(group.name.localized(), systemImage: systemImage(for: group.slug))) {
        ForEach(boards.filter { $0.group.id == group.id }) { board in
          NavigationLink(board.name.localized()) {
            PostListView(board: board)
          }
        }
      }
      .headerProminence(.increased)
    }
  }

  func systemImage(for slug: String) -> String {
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


#Preview {
  BoardListView()
}
