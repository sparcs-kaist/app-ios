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

      Tab("Timetable", systemImage: "square.grid.2x2") {
        TimetableView()
          .environment(timetableViewModel)
      }

      Tab("Taxi", systemImage: "car") {
        Text("Taxi")
      }

      Tab(role: .search) {
        NavigationStack {
          Text("Search")
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
