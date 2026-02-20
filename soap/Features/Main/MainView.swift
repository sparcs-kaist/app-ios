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
  @State private var selectedTab: TabSelection = .feed

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

      Tab("Timetable", systemImage: "square.grid.2x2", value: .timetable) {
        TimetableView()
      }

      Tab("Taxi", systemImage: "car", value: .taxi) {
        TaxiListView()
      }

      Tab(value: .search, role: .search) {
        SearchView()
      }
    }
    .tabBarMinimizeBehavior(.onScrollDown)
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
