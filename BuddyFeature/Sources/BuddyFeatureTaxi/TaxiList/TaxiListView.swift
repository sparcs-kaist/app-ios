//
//  TaxiListView.swift
//  soap
//
//  Created by Soongyu Kwon on 03/07/2025.
//

import Foundation
import SwiftUI
import BuddyDomain
import BuddyFeatureShared
import Haptica
import FirebaseAnalytics
import BuddyPreviewSupport

public struct TaxiListView: View {
  private enum Destination: Hashable {
    case chatList
  }

  @State var viewModel: TaxiListViewModelProtocol
  @Namespace private var namespace

  // view properties
  @State private var scrollTarget: String? = nil

  // show taxi room preview
  @State private var showRoomCreationSheet: Bool = false
  @State private var selectedRoom: TaxiRoom? = nil

  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass

  public init(viewModel: TaxiListViewModelProtocol = TaxiListViewModel()) {
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

  var description: String {
    switch (viewModel.source, viewModel.destination) {
    case let (source?, destination?):
      return String(localized: "No rooms found from \(source.title.localized()) to \(destination.title.localized()). Be the first one to create one!", bundle: .module)
    case let (source?, nil):
      return String(localized: "No rooms found from \(source.title.localized()) to any destination. Be the first one to create one!", bundle: .module)
    case let (nil, destination?):
      return String(localized: "No rooms found heading to \(destination.title.localized()). Be the first one to create one!", bundle: .module)
    case (nil, nil):
      return String(localized: "No rooms found for this week. Be the first one to create one!", bundle: .module)
    }
  }

  public var body: some View {
    ScrollViewReader { scrollViewProxy in
      ScrollView {
        LazyVStack(spacing: 16, pinnedViews: .sectionHeaders) {
          TaxiDestinationPicker(
            source: $viewModel.source,
            destination: $viewModel.destination,
            locations: viewModel.locations
          )
          .padding()
          .background(
            colorScheme == .light ? Color.secondarySystemGroupedBackground : Color.clear,
            in: .rect(cornerRadius: 28)
          )
          .glassEffect(colorScheme == .light ? .identity : .regular, in: .rect(cornerRadius: 28))
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
              case .empty:
                emptyView()
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
        Button(String(localized: "Create", bundle: .module), systemImage: "plus") {
          showRoomCreationSheet = true
        }
      }
      .matchedTransitionSource(id: "RoomCreationView", in: namespace)

      ToolbarSpacer(.flexible, placement: .topBarTrailing)

      ToolbarItem(placement: .topBarTrailing) {
        NavigationLink(value: Destination.chatList) {
          Label(String(localized: "Chats", bundle: .module), systemImage: "bubble.left.and.text.bubble.right")
        }
      }
    }
    .navigationTitle(horizontalSizeClass == .compact ? String(localized: "Taxi", bundle: .module) : "")
    .toolbarTitleDisplayMode(.inlineLarge)
    .background {
      BackgroundGradientView(color: .purple)
        .ignoresSafeArea()
    }
    .background(Color.systemGroupedBackground)
    .navigationDestination(for: Destination.self) { destination in
      switch destination {
      case .chatList:
        TaxiChatListView()
      }
    }
    .sheet(isPresented: $showRoomCreationSheet) {
      TaxiRoomCreationView(viewModel: viewModel)
        .navigationTransition(.zoom(sourceID: "RoomCreationView", in: namespace))
        .presentationDragIndicator(.visible)
    }
    .sheet(item: $selectedRoom) { room in
      TaxiPreviewView(room: room)
        .onDisappear {
          Task {
            await viewModel.fetchData()
          }
        }
        .presentationDragIndicator(.visible)
        .presentationDetents([.height(400), .height(500)])
    }
    .task {
      await viewModel.fetchData()
    }
    .refreshable {
      await viewModel.fetchData()
    }
    .analyticsScreen(name: "Taxi List", class: String(describing: Self.self))
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
        TaxiRoomCell(room: room, withOutBackground: false)
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
        emptyResultView
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
                TaxiRoomCell(room: room, withOutBackground: false)
                  .padding(.horizontal)
                  .id(day.weekdaySymbol)
                  .onTapGesture {
                    Haptic.selection.generate()
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
    .animation(.spring, value: viewModel.source)
    .animation(.spring, value: viewModel.destination)
  }

  private func emptyView() -> some View {
    ContentUnavailableView(String(localized: "No Rides This Week", bundle: .module), systemImage: "car.2.fill", description: Text("Looks like there are no groups scheduled for this week. Be the first to create one!", bundle: .module))
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

  private var emptyResultView: some View {
    ContentUnavailableView(
      label: {
        Label(String(localized: "No Rides Found", bundle: .module), systemImage: "car.2.fill")
      },
      description: {
        Text(description)
      },
      actions: {
        Button(String(localized: "Create a New Group", bundle: .module)) {
          showRoomCreationSheet = true
        }

        Button(String(localized: "Clear Selection", bundle: .module)) {
          viewModel.source = nil
          viewModel.destination = nil
        }
      }
    )
  }
}


// MARK: - Previews
#Preview("Loading State") {
  TaxiListView(viewModel: PreviewTaxiListViewModel(state: .loading))
}

#Preview("Loaded State") {
  let state = TaxiListViewState.loaded(
    rooms: TaxiRoom.mockList,
    locations: TaxiLocation.mockList
  )
  TaxiListView(viewModel: PreviewTaxiListViewModel(state: state))
}

#Preview("Empty State") {
  TaxiListView(viewModel: PreviewTaxiListViewModel(state: .empty))
}

#Preview("Error State") {
  TaxiListView(viewModel: PreviewTaxiListViewModel(state: .error(message: "Something went wrong")))
}
