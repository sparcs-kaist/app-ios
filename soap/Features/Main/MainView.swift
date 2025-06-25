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
      Tab("Home", systemImage: "house") {
        HomeView()
      }

      Tab("Boards", systemImage: "tray.full") {
        BoardListView()
      }

      Tab("Timetable", systemImage: "square.grid.2x2") {
        TimetableView()
          .environment(timetableViewModel)
      }

      Tab("Taxi", systemImage: "car") {
        NavigationStack {
          ContentUnavailableView("No Rooms", systemImage: "car.2.fill", description: Text("There is no existing room."))
            .navigationTitle("Taxi")
        }
      }

      Tab(role: .search) {
        NavigationStack {
          ContentUnavailableView.search
            .navigationTitle("Search")
        }
      }
    }
    .tabBarMinimizeBehavior(.onScrollDown)
    .searchable(text: $searchText)
  }
}

#Preview {
  MainView()
}
