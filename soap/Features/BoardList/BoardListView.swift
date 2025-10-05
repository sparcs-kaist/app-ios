//
//  BoardListView.swift
//  soap
//
//  Created by Soongyu Kwon on 03/06/2025.
//

import SwiftUI
import BuddyDomain

struct BoardListView: View {
  @State private var viewModel = BoardListViewModel()

  var body: some View {
    NavigationStack {
      List {
        switch viewModel.state {
        case .loading:
          loadingView
            .redacted(reason: .placeholder)
        case .loaded(let boards, let groups):
          loadedView(boards: boards, groups: groups)
        case .error(let message):
          ContentUnavailableView("Error", systemImage: "wifi.exclamationmark", description: Text(message))
        }
      }
      .listStyle(.sidebar)
      .disabled(viewModel.state == .loading)
      .navigationTitle("Boards")
      .toolbarTitleDisplayMode(.inlineLarge)
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

  @ViewBuilder
  var loadingView: some View {
    Section(header: Label("Notice", systemImage: "bell.badge.fill")) {
      NavigationLink("Portal Notice", destination: { })
      NavigationLink("Staff Notice", destination: { })
      NavigationLink("Facility Notice", destination: { })
      NavigationLink("External Company Advertisement", destination: { })
    }
    .headerProminence(.increased)

    Section(header: Label("Talk", systemImage: "text.bubble.fill")) {
      NavigationLink("General", destination: { })
    }
    .headerProminence(.increased)

    Section(header: Label("Organisations and Clubs", systemImage: "person.2.fill")) {
      NavigationLink("Students Group", destination: { })
      NavigationLink("Club", destination: { })
    }
    .headerProminence(.increased)

    Section(header: Label("Trade", systemImage: "tag.fill")) {
      NavigationLink("Wanted", destination: { })
      NavigationLink("Market", destination: { })
      NavigationLink("Real Estate", destination: { })
    }
    .headerProminence(.increased)

    Section(header: Label("Communication", systemImage: "envelope.open.fill")) {
      NavigationLink("Facility Feedback", destination: { })
      NavigationLink("Ara Feedback", destination: { })
      NavigationLink("Messages to the School", destination: { })
      NavigationLink("KAIST News", destination: { })
    }
    .headerProminence(.increased)
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
