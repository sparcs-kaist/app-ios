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
  @State private var taxiInviteId: String?
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
        BoardListView(boardListViewModel)
      }

      Tab("Timetable", systemImage: "square.grid.2x2", value: .timetable) {
        TimetableView()
      }

      Tab("Taxi", systemImage: "car", value: .taxi) {
        TaxiListView(taxiInviteId: $taxiInviteId)
      }

      Tab(value: .search, role: .search) {
        SearchView()
      }
    }
    .tabBarMinimizeBehavior(.onScrollDown)
    .onOpenURL { url in
      logger.debug(url.pathComponents)
      if let host = url.host, host.contains("taxi") {
        logger.debug("App started with taxi deeplink")
        selectedTab = .taxi
        
        taxiInviteId = String(url.lastPathComponent)
        logger.debug("Taxi Invitation Id: \(taxiInviteId ?? "nil")")
      }
    }
    .tabViewStyle(.tabBarOnly)
  }
}

//#Preview {
//  MainView(feedViewModel: MockFeedViewModel(), boardListViewModel: MockBoardListViewModel())
//}
