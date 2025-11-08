//
//  TaxiChatListView.swift
//  soap
//
//  Created by Soongyu Kwon on 13/07/2025.
//

import SwiftUI
import Factory
import BuddyDomain

struct TaxiChatListView: View {
  @State private var viewModel: TaxiChatListViewModelProtocol
  @State private var selectedRoom: TaxiRoom?
  
  private var onBack: (() -> Void)?

  init(viewModel: TaxiChatListViewModelProtocol = TaxiChatListViewModel(), onBack: (() -> Void)? = nil) {
    _viewModel = State(initialValue: viewModel)
    self.onBack = onBack
  }

  var body: some View {
    NavigationSplitView {
      ScrollView {
        LazyVStack(spacing: 16) {
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
        }
        .toolbar {
          ToolbarItem(placement: .topBarLeading) {
            Button("Back", systemImage: "chevron.left") {
              onBack?()
            }
          }
        }
        .navigationTitle(Text("Chats"))
        .navigationBarTitleDisplayMode(.inline)
        .padding()
      }
      .background {
        BackgroundGradientView(color: .purple)
          .ignoresSafeArea()
      }
      .background(Color.systemGroupedBackground)
      .navigationDestination(item: $selectedRoom) { room in
        TaxiChatView(room: room)
          .id(room.id)
      }
    } detail: {
      
    }
    .toolbar(.hidden, for: .tabBar)
    .task {
      await viewModel.fetchData()
    }
  }

  @ViewBuilder
  private var loadingView: some View {
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

  @ViewBuilder
  private func loadedView(onGoing: [TaxiRoom], done: [TaxiRoom]) -> some View {
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
            .overlay(selectedRoom == room ? Color.secondary : Color.clear, in: .rect(cornerRadius: 28))
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
            .overlay(selectedRoom == room ? Color.secondary : Color.clear, in: .rect(cornerRadius: 28))
        }
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
  return TaxiChatListView(viewModel: vm)
}

#Preview("Loaded State") {
  let vm = MockTaxiChatListViewModel()
  vm.state = .loaded(onGoing: Array(TaxiRoom.mockList.prefix(3)), done: Array(TaxiRoom.mockList.suffix(5)))
  return TaxiChatListView(viewModel: vm)
}

#Preview("Error State") {
  let vm = MockTaxiChatListViewModel()
  vm.state = .error(message: "Something went wrong")
  return TaxiChatListView(viewModel: vm)
}
