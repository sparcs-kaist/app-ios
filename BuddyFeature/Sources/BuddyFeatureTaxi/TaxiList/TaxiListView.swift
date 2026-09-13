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
  /// Backs the "Active Groups" section shown in the wide layout's left column.
  @State private var chatListViewModel: TaxiChatListViewModelProtocol = TaxiChatListViewModel()
  @Namespace private var namespace

  // view properties
  @State private var scrollTarget: String? = nil

  // show taxi room preview
  @State private var showRoomCreationSheet: Bool = false
  @State private var selectedRoom: TaxiRoom? = nil
  @State private var selectedChatRoom: TaxiRoom? = nil

  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass

  public init(viewModel: TaxiListViewModelProtocol = TaxiListViewModel()) {
    _viewModel = State(initialValue: viewModel)
  }

  init(
    viewModel: TaxiListViewModelProtocol,
    chatListViewModel: TaxiChatListViewModelProtocol
  ) {
    _viewModel = State(initialValue: viewModel)
    _chatListViewModel = State(initialValue: chatListViewModel)
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
    GeometryReader { reader in
      ScrollViewReader { scrollViewProxy in
        Group {
          if reader.size.width > LayoutMetrics.twoColumnWidthThreshold {
            wideLayout(scrollViewProxy: scrollViewProxy)
          } else {
            compactLayout(scrollViewProxy: scrollViewProxy)
          }
        }
        .onChange(of: scrollTarget) {
          withAnimation(.spring(duration: 0.35, bounce: 0.2, blendDuration: 0.15)) {
            viewModel.selectedDate = viewModel.week.first(where: { $0.weekdaySymbol == scrollTarget }) ?? Date()
          }
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
    .navigationDestination(item: $selectedChatRoom) { room in
      TaxiChatView(room: room)
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

  /// Single-column layout: everything scrolls together, with the weekday
  /// selector pinned as a section header.
  private func compactLayout(scrollViewProxy: ScrollViewProxy) -> some View {
    ScrollView {
      LazyVStack(spacing: 16, pinnedViews: .sectionHeaders) {
        destinationPicker

        Section {
          roomsContent
        } header: {
          weekDaySelector(scrollViewProxy: scrollViewProxy)
        }
      }
      .padding(.bottom)
      .contentWidth()
    }
    .scrollEdgeEffectStyle(.soft, for: .top)
    .scrollPosition(id: $scrollTarget, anchor: .top)
  }

  /// Two-column layout for wide screens: pickers and active chat groups scroll
  /// on the left half while the room list scrolls on the right half.
  private func wideLayout(scrollViewProxy: ScrollViewProxy) -> some View {
    HStack(alignment: .top, spacing: 0) {
      ScrollView {
        VStack(spacing: 16) {
          destinationPicker

          weekDaySelector(scrollViewProxy: scrollViewProxy)

          activeChatGroups
        }
        .padding(.bottom)
        .contentWidth()
      }
      .scrollEdgeEffectStyle(.soft, for: .top)
      .task {
        await chatListViewModel.fetchData()
      }

      ScrollView {
        LazyVStack(spacing: 16) {
          roomsContent
        }
        .padding(.bottom)
        .contentWidth()
      }
      .scrollEdgeEffectStyle(.soft, for: .top)
      .scrollPosition(id: $scrollTarget, anchor: .top)
    }
  }

  private var destinationPicker: some View {
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
  }

  private func weekDaySelector(scrollViewProxy: ScrollViewProxy) -> some View {
    WeekDaySelector(selectedDate: $viewModel.selectedDate, week: viewModel.week) { day in
      scrollViewProxy.scrollTo(day.weekdaySymbol, anchor: .top)
    }
    .padding(.horizontal)
    .redacted(reason: isInteractable ? [] : .placeholder)
    .disabled(!isInteractable)
  }

  /// The user's on-going chat groups, shown below the pickers in the wide
  /// layout. Errors stay silent here — the full chat list remains reachable
  /// from the toolbar.
  @ViewBuilder
  private var activeChatGroups: some View {
    switch chatListViewModel.state {
    case .loading:
      TaxiRoomGroupSection(
        title: String(localized: "Active Groups", bundle: .module),
        rooms: Array(TaxiRoom.mockList.prefix(2)),
        selectedRoom: nil,
        taxiUser: nil,
        onSelect: { _ in }
      )
      .padding(.horizontal)
      .redacted(reason: .placeholder)
      .disabled(true)
    case .loaded(let onGoing, _):
      if !onGoing.isEmpty {
        TaxiRoomGroupSection(
          title: String(localized: "Active Groups", bundle: .module),
          rooms: onGoing,
          selectedRoom: selectedChatRoom,
          taxiUser: chatListViewModel.taxiUser,
          onSelect: { room in
            Haptic.selection.generate()
            selectedChatRoom = room
          }
        )
        .padding(.horizontal)
      }
    case .error:
      EmptyView()
    }
  }

  private var roomsContent: some View {
    Group {
      switch viewModel.state {
      case .loading:
        loadingView()
      case .loaded(let rooms, _):
        TaxiRoomWeekList(
          rooms: rooms,
          week: viewModel.week,
          source: viewModel.source,
          destination: viewModel.destination,
          emptyDescription: description,
          onSelectRoom: { room in
            Haptic.selection.generate()
            selectedRoom = room
          },
          onCreateRoom: { showRoomCreationSheet = true },
          onClearSelection: {
            viewModel.source = nil
            viewModel.destination = nil
          }
        )
      case .empty:
        emptyView()
      case .error(let message):
        errorView(errorMessage: message)
      }
    }
    .transition(.opacity.animation(.easeInOut(duration: 0.3)))
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
  TaxiListView(
    viewModel: PreviewTaxiListViewModel(state: state),
    chatListViewModel: PreviewTaxiChatListViewModel(
      state: .loaded(onGoing: Array(TaxiRoom.mockList.prefix(2)), done: [])
    )
  )
}

#Preview("Empty State") {
  TaxiListView(viewModel: PreviewTaxiListViewModel(state: .empty))
}

#Preview("Error State") {
  TaxiListView(viewModel: PreviewTaxiListViewModel(state: .error(message: "Something went wrong")))
}
