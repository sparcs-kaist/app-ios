//
//  TaxiListView.swift
//  soap
//
//  Created by Soongyu Kwon on 03/07/2025.
//

import SwiftUI

struct TaxiListView: View {
  @State private var origin: TaxiLocation?
  @State private var destination: TaxiLocation?
  @State private var selectedDate: Date = Date()
  @State var viewModel: TaxiListViewModelProtocol

  init(viewModel: TaxiListViewModelProtocol = TaxiListViewModel()) {
    _viewModel = State(initialValue: viewModel)
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        Group {
          switch viewModel.state {
          case .loading:
            loadingView()
          case .loaded(let rooms, let locations):
            loadedView(rooms: rooms, locations: locations)
          case .empty(let locations):
            emptyView(locations: locations)
          case .error(let message):
            errorView(errorMessage: message)
          }
        }
        .transition(.opacity.animation(.easeInOut(duration: 0.3)))
      }
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Create", systemImage: "plus") { }
        }
      }
      .navigationTitle("Taxi")
      .background(Color.secondarySystemBackground)
    }
    .task {
      await viewModel.fetchData()
    }
  }

  private func loadingView() -> some View {
    LazyVStack(spacing: 16, pinnedViews: .sectionHeaders) {
      TaxiDestinationPicker(origin: $origin, destination: $destination, locations: TaxiLocation.mockList)
        .padding()
        .background(Color.systemBackground, in: .rect(cornerRadius: 28))
        .padding(.horizontal)
        .redacted(reason: .placeholder)
        .disabled(true)


      Section {
        ForEach(TaxiRoom.mockList) { room in
          TaxiRoomCell(room: room)
            .padding(.horizontal)
            .redacted(reason: .placeholder)
            .disabled(true)
        }
      } header: {
        WeekDaySelector(selectedDate: $selectedDate)
          .padding(.horizontal)
          .redacted(reason: .placeholder)
          .disabled(true)
      }
    }
  }

  private func loadedView(rooms: [TaxiRoom], locations: [TaxiLocation]) -> some View {
    LazyVStack(spacing: 16, pinnedViews: .sectionHeaders) {
      TaxiDestinationPicker(origin: $origin, destination: $destination, locations: locations)
        .padding()
        .background(Color.systemBackground, in: .rect(cornerRadius: 28))
        .padding(.horizontal)


      Section {
        ForEach(rooms) { room in
          TaxiRoomCell(room: room)
            .padding(.horizontal)
        }
      } header: {
        WeekDaySelector(selectedDate: $selectedDate)
          .padding(.horizontal)
      }
    }
  }

  private func emptyView(locations: [TaxiLocation]) -> some View {
    LazyVStack(spacing: 16, pinnedViews: .sectionHeaders) {
      TaxiDestinationPicker(origin: $origin, destination: $destination, locations: locations)
        .padding()
        .background(Color.systemBackground, in: .rect(cornerRadius: 28))
        .padding(.horizontal)


      Section {
        ContentUnavailableView("No Rooms", systemImage: "car.2.fill", description: Text("There is no existing room for this week."))
      } header: {
        WeekDaySelector(selectedDate: $selectedDate)
          .padding(.horizontal)
      }
    }
  }

  private func errorView(errorMessage: String) -> some View {
    LazyVStack(spacing: 16, pinnedViews: .sectionHeaders) {
      TaxiDestinationPicker(origin: $origin, destination: $destination, locations: TaxiLocation.mockList)
        .padding()
        .background(Color.systemBackground, in: .rect(cornerRadius: 28))
        .padding(.horizontal)
        .redacted(reason: .placeholder)
        .disabled(true)


      Section {
        ContentUnavailableView(
          label: {
            Label("Error", systemImage: "exclamationmark.triangle")
          },
          description: {
            Text(errorMessage)
          },
          actions: {
            Button("Try Again") { }
          }
        )
      } header: {
        WeekDaySelector(selectedDate: $selectedDate)
          .padding(.horizontal)
          .redacted(reason: .placeholder)
          .disabled(true)
      }
    }
  }
}


#Preview("Loading State") {
  let vm = MockTaxiListViewModel()
  vm.state = .loading
  return TaxiListView(viewModel: vm)
}

#Preview("Loaded State") {
  let vm = MockTaxiListViewModel()
  vm.state = .loaded(
    rooms: TaxiRoom.mockList,
    locations: TaxiLocation.mockList
  )
  return TaxiListView(viewModel: vm)
}

#Preview("Empty State") {
  let vm = MockTaxiListViewModel()
  vm.state = .empty(locations: TaxiLocation.mockList)
  return TaxiListView(viewModel: vm)
}

#Preview("Error State") {
  let vm = MockTaxiListViewModel()
  vm.state = .error(message: "Something went wrong")
  return TaxiListView(viewModel: vm)
}
