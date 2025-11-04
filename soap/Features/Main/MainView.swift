//
//  MainView.swift
//  soap
//
//  Created by Soongyu Kwon on 12/06/2025.
//

import SwiftUI
import BuddyDomain

struct MainView: View {
  @State private var taxiInviteId: String?
  @State private var selectedTab: TabSelection = .feed

  var body: some View {
    TabView(selection: $selectedTab) {
      Tab("Feed", systemImage: "text.rectangle.page", value: .feed) {
        FeedView()
      }

      Tab("Boards", systemImage: "tray.full", value: .board) {
        BoardListView()
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
    .tabViewStyle(.sidebarAdaptable)
  }
}

#Preview {
  MainView()
}
