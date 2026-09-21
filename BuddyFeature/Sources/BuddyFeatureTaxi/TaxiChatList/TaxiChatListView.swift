//
//  TaxiChatListView.swift
//  soap
//
//  Created by Soongyu Kwon on 13/07/2025.
//

import Foundation
import SwiftUI
import Factory
import BuddyDomain
import BuddyFeatureShared
import FirebaseAnalytics
import BuddyPreviewSupport

/// Presented as its own root (a full-screen cover from `TaxiListView`) rather
/// than pushed onto the Taxi navigation stack, so it can own a real
/// `NavigationSplitView`. That is what earns the system behaviour this screen
/// used to hand-roll: collapsing to a single column on narrow displays, and —
/// on iPhone Duo — sizing its columns so the fold falls between them.
struct TaxiChatListView: View {
  @State private var viewModel: TaxiChatListViewModelProtocol
  @State private var selectedRoom: TaxiRoom?

  /// Keeps the room list on screen once a chat is showing, rather than letting
  /// the system hide it to give the detail more room.
  @State private var columnVisibility: NavigationSplitViewVisibility = .all

  /// Which column the collapsed split view shows. Only consulted when the
  /// display is too narrow for two columns at all; the room list is a custom
  /// `ScrollView` rather than a `List(selection:)`, so the split view cannot
  /// infer the push from the selection on its own.
  @State private var preferredCompactColumn: NavigationSplitViewColumn = .sidebar

  @Environment(\.dismiss) private var dismiss

  init(viewModel: TaxiChatListViewModelProtocol = TaxiChatListViewModel()) {
    _viewModel = State(initialValue: viewModel)
  }

  var body: some View {
    NavigationSplitView(
      columnVisibility: $columnVisibility,
      preferredCompactColumn: $preferredCompactColumn
    ) {
      roomList
        .navigationTitle(Text("Chats", bundle: .module))
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button(String(localized: "Close", bundle: .module), systemImage: "xmark") {
              dismiss()
            }
          }
        }
    } detail: {
      if let selectedRoom {
        TaxiChatView(room: selectedRoom)
          .id(selectedRoom.id)
      } else {
        ContentUnavailableView {
          Label(String(localized: "Select a room", bundle: .module), systemImage: "bubble.left.and.text.bubble.right")
        }
      }
    }
    // `.balanced` shrinks the detail to make room for the sidebar instead of
    // hiding the sidebar to keep the detail large, so the chat appears beside
    // the room list rather than in place of it.
    .navigationSplitViewStyle(.balanced)
    .onChange(of: selectedRoom) { _, room in
      preferredCompactColumn = room == nil ? .sidebar : .detail
    }
    .task {
      await viewModel.fetchData()
    }
    .analyticsScreen(name: "Taxi Chat List", class: String(describing: Self.self))
  }

  /// The sidebar column: one presentation for every state, so the title and
  /// background no longer have to be re-applied per case.
  @ViewBuilder
  private var roomList: some View {
    Group {
      switch viewModel.state {
      case .loading:
        loadingView
      case .loaded(let onGoing, let done):
        loadedView(onGoing: onGoing, done: done)
      case .error(let message):
        errorView(errorMessage: message)
      }
    }
    .transition(.opacity.animation(.easeInOut(duration: 0.3)))
    .background(Color.systemGroupedBackground)
    .background {
      BackgroundGradientView(color: .purple)
        .ignoresSafeArea()
    }
  }

  @ViewBuilder
  private var loadingView: some View {
    ScrollView {
      LazyVStack(spacing: 16) {
        LazyVStack(spacing: 12) {
          HStack {
            Text("Active Groups", bundle: .module)
              .font(.title3)
              .fontWeight(.bold)

            Spacer()
          }

          ForEach(TaxiRoom.mockList.prefix(3)) { room in
            TaxiRoomCell(room: room, withOutBackground: false)
              .redacted(reason: .placeholder)
          }
        }

        LazyVStack(spacing: 12) {
          HStack {
            Text("Past Groups", bundle: .module)
              .font(.title3)
              .fontWeight(.bold)

            Spacer()
          }

          ForEach(TaxiRoom.mockList.prefix(5)) { room in
            TaxiRoomCell(room: room, withOutBackground: false)
              .redacted(reason: .placeholder)
          }
        }
      }
      .padding()
      .contentWidth()
    }
  }

  @ViewBuilder
  private func loadedView(onGoing: [TaxiRoom], done: [TaxiRoom]) -> some View {
    ScrollView {
      LazyVStack(spacing: 16) {
        if !onGoing.isEmpty {
          TaxiRoomGroupSection(
            title: String(localized: "Active Groups", bundle: .module),
            rooms: onGoing,
            selectedRoom: selectedRoom,
            taxiUser: viewModel.taxiUser,
            onSelect: { selectedRoom = $0 }
          )
        }

        if !done.isEmpty {
          TaxiRoomGroupSection(
            title: String(localized: "Past Groups", bundle: .module),
            rooms: done,
            selectedRoom: selectedRoom,
            taxiUser: viewModel.taxiUser,
            onSelect: { selectedRoom = $0 }
          )
        }
      }
      .padding()
      .contentWidth()
    }
  }

  private func errorView(errorMessage: String) -> some View {
    ContentUnavailableView(
      label: {
        Label(String(localized: "Error", bundle: .module), systemImage: "fuelpump.exclamationmark.fill")
      },
      description: {
        Text(errorMessage)
      },
      actions: {
        Button(String(localized: "Try Again", bundle: .module)) {
          Task {
            await viewModel.fetchData()
          }
        }
      }
    )
  }
}


// MARK: - Previews
// The view provides its own NavigationSplitView, so previews must not wrap it
// in a navigation container.
#Preview("Loading State") {
  TaxiChatListView(viewModel: PreviewTaxiChatListViewModel(state: .loading))
}

#Preview("Loaded State") {
  let state = TaxiChatListViewState.loaded(onGoing: Array(TaxiRoom.mockList.prefix(3)), done: Array(TaxiRoom.mockList.suffix(5)))

  return TaxiChatListView(viewModel: PreviewTaxiChatListViewModel(state: state))
}

#Preview("Error State") {
  TaxiChatListView(viewModel: PreviewTaxiChatListViewModel(state: .error(message: "Something went wrong")))
}
