//
//  TaxiListView.swift
//  soap
//
//  Created by Soongyu Kwon on 03/07/2025.
//

import SwiftUI

struct TaxiListView: View {
  @State var viewModel: TaxiListViewModelProtocol

  // view properties
  @State private var scrollTarget: String? = nil

  // show taxi room preview
  @State private var showRoomCreationSheet: Bool = false
  @State private var selectedRoom: TaxiRoom? = nil

  // show taxi chats
  @State private var showChat: Bool = false

  init(viewModel: TaxiListViewModelProtocol = TaxiListViewModel()) {
    _viewModel = State(initialValue: viewModel)
  }

  private var isInteractable: Bool {
    switch viewModel.state {
    case .loaded, .empty:
      true
    default:
      false
    }
  }

  var body: some View {
    NavigationStack {
      ScrollViewReader { scrollViewProxy in
        ScrollView {
          LazyVStack(spacing: 16, pinnedViews: .sectionHeaders) {
            TaxiDestinationPicker(
              source: $viewModel.source,
              destination: $viewModel.destination,
              locations: viewModel.locations
            )
              .padding()
              .background(Color.systemBackground, in: .rect(cornerRadius: 28))
              .padding(.horizontal)
              .redacted(reason: isInteractable ? [] : .placeholder)
              .disabled(!isInteractable)

            Section {
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
            } header: {
              WeekDaySelector(selectedDate: $viewModel.selectedDate, week: viewModel.week)  { day in
                scrollViewProxy.scrollTo(day.weekdaySymbol, anchor: .center)
              }
                .padding(.horizontal)
                .redacted(reason: isInteractable ? [] : .placeholder)
                .disabled(!isInteractable)
            }
          }
          .padding(.bottom)
        }
        .scrollPosition(id: $scrollTarget, anchor: .top)
        .onChange(of: scrollTarget) {
          withAnimation(.spring(duration: 0.35, bounce: 0.2, blendDuration: 0.15)) {
            viewModel.selectedDate = viewModel.week.first(where: { $0.weekdaySymbol == scrollTarget }) ?? Date()
          }
        }
      }
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Chats", systemImage: "bubble.left.and.text.bubble.right") {
            showChat = true
          }
        }

        ToolbarSpacer(.flexible, placement: .topBarTrailing)

        ToolbarItem(placement: .topBarTrailing) {
          Button("Create", systemImage: "plus") {
            showRoomCreationSheet = true
          }
        }
      }
      .sheet(isPresented: $showRoomCreationSheet) {
        TaxiRoomCreationView(viewModel: viewModel)
          .presentationDragIndicator(.visible)
      }
      .navigationTitle("Taxi")
      .background(Color.secondarySystemBackground)
    }
    .sheet(item: $selectedRoom) { room in
      TaxiPreviewView(room: room)
        .presentationDragIndicator(.visible)
        .presentationDetents([.height(400), .height(500)])
    }
    .sheet(isPresented: $showChat) {
      TaxiChatListView()
        .presentationDragIndicator(.visible)
    }
    .onAppear {
      print("hello")
    }
    .task {
      await viewModel.fetchData()
    }
  }


  private func loadingView() -> some View {
    VStack(spacing: 12) {

      HStack(alignment: .bottom) {
        Text(Date().weekdaySymbol)
          .font(.title3)
          .fontWeight(.bold)
        Spacer()
      }
      .padding(.horizontal)

      ForEach(TaxiRoom.mockList.prefix(4)) { room in
        TaxiRoomCell(room: room)
          .padding(.horizontal)
      }
    }
    .redacted(reason: .placeholder)
    .disabled(true)
  }

  private func loadedView(rooms: [TaxiRoom], locations: [TaxiLocation]) -> some View {
    let calendar = Calendar.current
    let filteredRooms: [TaxiRoom] = rooms.filter { room in
      let matchessource = viewModel.source == nil || room.source.id == viewModel.source!.id
      let matchesDestination = viewModel.destination == nil || room.destination.id == viewModel.destination!.id
      return matchessource && matchesDestination
    }

    return Group {
      if  filteredRooms.isEmpty {
        var description: String {
          switch (viewModel.source, viewModel.destination) {
          case let (source?, destination?):
            return "No rooms found from \(source.title.localized()) to \(destination.title.localized()). Be the first one to create one!"
          case let (source?, nil):
            return "No rooms found from \(source.title.localized()) to any destination. Be the first one to create one!"
          case let (nil, destination?):
            return "No rooms found heading to \(destination.title.localized()). Be the first one to create one!"
          case (nil, nil):
            return "No rooms found for this week. Be the first one to create one!"
          }
        }

        ContentUnavailableView(
          label: {
            Label("No Rides Found", systemImage: "car.2.fill")
          },
          description: {
            Text(description)
          },
          actions: {
            Button("Create a New Room") {
              showRoomCreationSheet = true
            }

            Button("Clear Selection") {
              viewModel.source = nil
              viewModel.destination = nil
            }
          }
        )
      } else {
        ForEach(viewModel.week, id: \.self.weekdaySymbol) { day in
          let roomsForDay = filteredRooms.filter { calendar.isDate($0.departAt, inSameDayAs: day) }
          if !roomsForDay.isEmpty {
            VStack(spacing: 12) {
              HStack(alignment: .bottom) {
                Text(day.weekdaySymbol)
                  .font(.title3)
                  .fontWeight(.bold)
                Spacer()
              }
              .padding(.horizontal)

              ForEach(roomsForDay) { room in
                TaxiRoomCell(room: room)
                  .padding(.horizontal)
                  .id(day.weekdaySymbol)
                  .onTapGesture {
                    selectedRoom = room
                  }
              }
            }
            .id(day.weekdaySymbol)
            .scrollTargetLayout()
          }
        }
      }
    }
  }

  private func emptyView(locations: [TaxiLocation]) -> some View {
    ContentUnavailableView("No Rides This Week", systemImage: "car.2.fill", description: Text("Looks like there are no rooms scheduled for this week. Be the first to create one!"))
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
