//
//  MainView.swift
//  soap
//
//  Created by Soongyu Kwon on 12/06/2025.
//

import SwiftUI

struct MainView: View {
  private var timetableViewModel = TimetableViewModel()
  @State private var taxiInviteId: String?
  @State private var searchText: String = ""
  @State private var selectedTab: TabSelection = .feed

  var body: some View {
    TabView(selection: $selectedTab) {
      Tab("Feed", systemImage: "text.rectangle.page", value: .feed) {
        FeedView()
      }

//      Tab("My", systemImage: "person") {
//        HomeView()
//      }

      Tab("Boards", systemImage: "tray.full", value: .board) {
        BoardListView()
      }

      Tab("Timetable", systemImage: "square.grid.2x2", value: .timetable) {
        TimetableView()
          .environment(timetableViewModel)
      }

      Tab("Taxi", systemImage: "car", value: .taxi) {
        TaxiListView(taxiInviteId: $taxiInviteId)
      }

      Tab(value: .search, role: .search) {
        NavigationStack {
          ContentUnavailableView.search
            .navigationTitle("Search")
        }
        .searchable(text: $searchText)
      }
    }
    .tabBarMinimizeBehavior(.onScrollDown)
    .onOpenURL { url in
      if url.absoluteString.contains("taxi") {
        logger.debug("App started with taxi deeplink")
        selectedTab = .taxi
        
        guard let roomId = url.absoluteString.split(separator: "/").last else { return } // TODO: invalid invitation handling
        taxiInviteId = String(roomId)
        logger.debug("Taxi Invitation Id: \(roomId)")
      }
    }
  }
}

#Preview {
  MainView()
}
