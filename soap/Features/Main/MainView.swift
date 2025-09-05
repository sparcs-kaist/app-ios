//
//  MainView.swift
//  soap
//
//  Created by Soongyu Kwon on 12/06/2025.
//

import SwiftUI

struct MainView: View {
  private var timetableViewModel = TimetableViewModel()
  @State private var searchText: String = ""

  var body: some View {
    TabView {
      Tab("Feed", systemImage: "text.rectangle.page") {
        FeedView()
      }

//      Tab("My", systemImage: "person") {
//        HomeView()
//      }

      Tab("Boards", systemImage: "tray.full") {
        BoardListView()
      }

      Tab("Timetable", systemImage: "square.grid.2x2") {
        TimetableView()
          .environment(timetableViewModel)
      }

      Tab("Taxi", systemImage: "car") {
        TaxiListView()
      }

      Tab(role: .search) {
        NavigationStack {
          ContentUnavailableView.search
            .navigationTitle("Search")
        }
        .searchable(text: $searchText)
      }
    }
    .tabBarMinimizeBehavior(.onScrollDown)
  }
}

#Preview {
  MainView()
}
