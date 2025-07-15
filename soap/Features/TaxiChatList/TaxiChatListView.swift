//
//  TaxiChatListView.swift
//  soap
//
//  Created by Soongyu Kwon on 13/07/2025.
//

import SwiftUI
import Factory

struct TaxiChatListView: View {
  @State private var viewModel: TaxiChatListViewModelProtocol
  @Injected(\.taxiChatUseCase) private var taxiChatUseCase: TaxiChatUseCaseProtocol

  init(viewModel: TaxiChatListViewModelProtocol = TaxiChatListViewModel()) {
    _viewModel = State(initialValue: viewModel)
  }

  var body: some View {
    NavigationStack {
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
        .padding()
      }
      .navigationTitle(Text("Chats"))
      .background(Color.secondarySystemBackground)
    }
    .task {
      await viewModel.fetchData()
    }
  }

  @ViewBuilder
  private var loadingView: some View {
    LazyVStack(spacing: 12) {
      HStack {
        Text("Active Rooms")
          .font(.title3)
          .fontWeight(.bold)

        Spacer()
      }

      ForEach(TaxiRoom.mockList.prefix(3)) { room in
        TaxiRoomCell(room: room)
          .redacted(reason: .placeholder)
      }
    }

    LazyVStack(spacing: 12) {
      HStack {
        Text("Past Rooms")
          .font(.title3)
          .fontWeight(.bold)

        Spacer()
      }

      ForEach(TaxiRoom.mockList.prefix(5)) { room in
        TaxiRoomCell(room: room)
          .redacted(reason: .placeholder)
      }
    }
  }

  @ViewBuilder
  private func loadedView(onGoing: [TaxiRoom], done: [TaxiRoom]) -> some View {
    LazyVStack(spacing: 12) {
      HStack {
        Text("Active Rooms")
          .font(.title3)
          .fontWeight(.bold)

        Spacer()
      }

      ForEach(onGoing) { room in
        TaxiRoomCell(room: room)
          .onTapGesture {
            taxiChatUseCase.connect(to: room)
          }
      }
    }

    LazyVStack(spacing: 12) {
      HStack {
        Text("Past Rooms")
          .font(.title3)
          .fontWeight(.bold)

        Spacer()
      }

      ForEach(done) { room in
        TaxiRoomCell(room: room)
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
