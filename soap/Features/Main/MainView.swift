//
//  MainView.swift
//  soap
//
//  Created by Soongyu Kwon on 12/06/2025.
//

import SwiftUI
import BuddyDomain
import BuddyFeatureTimetable
import BuddyFeatureFeed
import BuddyFeaturePost
import BuddyFeatureTaxi
import BuddyFeatureSearch

struct MainView: View {
  @State private var viewModel = MainViewModel()
  @State private var timetableViewModel = V2TimetableViewModel()
  @State private var selectedTab: TabSelection = .feed
  @State private var extendTimetableView: Bool = false

  @Namespace private var namespace

  private var feedViewModel: FeedViewModelProtocol
  private var boardListViewModel: BoardListViewModelProtocol

  init(feedViewModel: FeedViewModelProtocol = FeedViewModel(), boardListViewModel: BoardListViewModelProtocol = BoardListViewModel()) {
    self.feedViewModel = feedViewModel
    self.boardListViewModel = boardListViewModel
  }

  var body: some View {
    TabView(selection: $selectedTab) {
      Tab("Feed", systemImage: "text.rectangle.page", value: .feed) {
        FeedView(feedViewModel)
      }

      Tab("Boards", systemImage: "tray.full", value: .board) {
        BoardListView(boardListViewModel, deepLinkedPost: $viewModel.deepLinkedPost)
      }

//      Tab("Map", systemImage: "map", value: .map) {
//
//      }

      Tab("Taxi", systemImage: "car", value: .taxi) {
        TaxiListView()
      }

      Tab(value: .search, role: .search) {
        SearchView()
      }
    }
    .tabBarMinimizeBehavior(.onScrollDown)
    .tabViewBottomAccessory {
      HStack {
        Circle()
          .fill(.indigo)
          .frame(width: 12, height: 12)

        VStack(alignment: .leading) {
          Text("System Programming")
            .font(.headline)
          Text("E3-1 1201")
            .font(.footnote)
            .foregroundStyle(.secondary)
        }

        Spacer()

        Text("in 10m")
          .fontDesign(.rounded)
          .font(.callout)
      }
      .padding()
      .matchedTransitionSource(id: "TimetableViewSource", in: namespace)
      .onTapGesture {
        extendTimetableView = true
      }
    }
    .fullScreenCover(isPresented: $extendTimetableView) {
      V2TimetableView(timetableViewModel)
        .safeAreaInset(edge: .top) {
          Capsule()
            .fill(.primary.secondary)
            .frame(width: 36, height: 4)
        }
        .navigationTransition(.zoom(sourceID: "TimetableViewSource", in: namespace))
    }
    .onOpenURL { url in
      guard let deepLink = DeepLink(url: url) else { return }
      handle(deepLink: deepLink)
    }
    .onReceive(NotificationCenter.default.publisher(for: .buddyInternalDeepLink)) { notification in
      guard let deepLink = notification.object as? DeepLink else { return }
      handle(deepLink: deepLink)
    }
    .sheet(item: $viewModel.invitedRoom) { room in
      TaxiPreviewView(room: room)
        .presentationDragIndicator(.visible)
        .presentationDetents([.height(400), .height(500)])
    }
    .alert(viewModel.alertState?.title ?? "Error", isPresented: $viewModel.isAlertPresented) {
      Button("Okay", role: .cancel) { }
    } message: {
      Text(viewModel.alertState?.message ?? "Unexpected Error")
    }
    .task {
      await timetableViewModel.setup()
    }
    .tabViewStyle(.tabBarOnly)
  }

  private func handle(deepLink: DeepLink) {
    switch deepLink {
    case .taxiInvite(let code):
      selectedTab = .taxi
      Task {
        await viewModel.resolveInvite(code: code)
      }
    case .araPost(let id):
      selectedTab = .board
      Task {
        await viewModel.resolvePost(id: id)
      }
    }
  }
}

//#Preview {
//  MainView(feedViewModel: MockFeedViewModel(), boardListViewModel: MockBoardListViewModel())
//}
