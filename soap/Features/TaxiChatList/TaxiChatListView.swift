//
//  TaxiChatListView.swift
//  soap
//
//  Created by Soongyu Kwon on 13/07/2025.
//

import SwiftUI
import Factory
import BuddyDomain
import BuddyFeatureShared

struct TaxiChatListView: View {
  @State private var viewModel: TaxiChatListViewModelProtocol
  @State private var selectedRoom: TaxiRoom?
  
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass

  init(viewModel: TaxiChatListViewModelProtocol = TaxiChatListViewModel()) {
    _viewModel = State(initialValue: viewModel)
  }

  var body: some View {
    Group {
      switch viewModel.state {
      case .loading:
        loadingView
        .navigationTitle(Text("Chats"))
        .background(Color.systemGroupedBackground)
      case .loaded(let onGoing, let done):
        if horizontalSizeClass == .compact {
          loadedView(onGoing: onGoing, done: done)
            .navigationDestination(item: $selectedRoom, destination: { room in
              TaxiChatView(room: room)
            })
            .navigationTitle(Text("Chats"))
        } else {
          loadedLargeView(onGoing: onGoing, done: done)
        }
      case .error(let message):
        errorView(errorMessage: message)
      }
    }
    .transition(.opacity.animation(.easeInOut(duration: 0.3)))
    .toolbar(.hidden, for: .tabBar)
    .task {
      await viewModel.fetchData()
    }
  }
  
  private func loadedLargeView(onGoing: [TaxiRoom], done: [TaxiRoom]) -> some View {
    HStack(spacing: 0) {
      loadedView(onGoing: onGoing, done: done)
        .containerRelativeFrame([.horizontal], { length, _ in
          length * 0.4
        })
      if let selectedRoom {
        TaxiChatView(room: selectedRoom)
          .id(selectedRoom.id)
          .toolbar(removing: .title)
      } else {
        Text("Select a room")
          .frame(maxWidth: .infinity)
          .foregroundStyle(.secondary)
      }
    }
  }

  @ViewBuilder
  private var loadingView: some View {
    ScrollView {
      LazyVStack(spacing: 16) {
        LazyVStack(spacing: 12) {
          HStack {
            Text("Active Groups")
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
            Text("Past Groups")
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
    }
  }

  @ViewBuilder
  private func loadedView(onGoing: [TaxiRoom], done: [TaxiRoom]) -> some View {
    ScrollView {
      if horizontalSizeClass != .compact {
        HStack {
          Text("Chats")
            .font(.largeTitle)
            .bold()
            .padding()
          Spacer()
        }
      }
      
      LazyVStack(spacing: 16) {
        if !onGoing.isEmpty {
          LazyVStack(spacing: 12) {
            HStack {
              Text("Active Groups")
                .font(.title3)
                .fontWeight(.bold)

              Spacer()
            }

            ForEach(onGoing) { room in
              TaxiRoomCell(room: room, withOutBackground: false)
                .environment(\.taxiUser, viewModel.taxiUser)
                .onTapGesture {
                  selectedRoom = room
                }
                .overlay(
                  Color.secondary.opacity(selectedRoom == room ? 0.3 : 0),
                  in: .rect(cornerRadius: 28)
                )
            }
          }
        }

        if !done.isEmpty {
          LazyVStack(spacing: 12) {
            HStack {
              Text("Past Groups")
                .font(.title3)
                .fontWeight(.bold)

              Spacer()
            }

            ForEach(done) { room in
              TaxiRoomCell(room: room, withOutBackground: false)
                .environment(\.taxiUser, viewModel.taxiUser)
                .onTapGesture {
                  selectedRoom = room
                }
                .overlay(
                  Color.secondary.opacity(selectedRoom == room ? 0.3 : 0),
                  in: .rect(cornerRadius: 28)
                )
            }
          }
        }
      }
      .padding()
    }
    .background(Color.systemGroupedBackground)
    .background {
      if horizontalSizeClass == .compact {
        BackgroundGradientView(color: .purple)
          .ignoresSafeArea()
      }
    }
  }

  private func errorView(errorMessage: String) -> some View {
    ContentUnavailableView(
      label: {
        Label("Error", systemImage: "fuelpump.exclamationmark.fill")
      },
      description: {
        Text(errorMessage)
      },
      actions: {
        Button("Try Again") {
          Task {
            await viewModel.fetchData()
          }
        }
      }
    )
  }
}


// MARK: - Previews
#Preview("Loading State") {
  let vm = MockTaxiChatListViewModel()
  vm.state = .loading
  return NavigationStack {
    TaxiChatListView(viewModel: vm)
  }
}

#Preview("Loaded State") {
  let vm = MockTaxiChatListViewModel()
  vm.state = .loaded(onGoing: Array(TaxiRoom.mockList.prefix(3)), done: Array(TaxiRoom.mockList.suffix(5)))
  return NavigationStack {
    TaxiChatListView(viewModel: vm)
  }
}

#Preview("Error State") {
  let vm = MockTaxiChatListViewModel()
  vm.state = .error(message: "Something went wrong")
  return NavigationStack {
    TaxiChatListView(viewModel: vm)
  }
}
