//
//  ContentView.swift
//  soap
//
//  Created by Soongyu Kwon on 30/10/2024.
//

import SwiftUI

struct ContentView: View {
  private var timetableViewModel = TimetableViewModel()
  @State private var selectedTab: String = "Home"

  var body: some View {
    NavigationStack {
      TabView(selection: $selectedTab) {
        Tab("Home", systemImage: "house", value: "Home") {
          VStack {
            NavigationLink {
              PostListView()
            } label: {
              Text("go to post list")
            }
          }
          .toolbarBackground(.visible, for: .tabBar)
        }

        Tab("Timetable", systemImage: "square.grid.2x2", value: "Timetable") {
          TimetableView()
            .environment(timetableViewModel)
            .toolbarBackground(.visible, for: .tabBar)
        }

        Tab("Taxi", systemImage: "car", value: "Taxi") {
          TaxiView()
            .toolbarBackground(.visible, for: .tabBar)
        }

        Tab("More", systemImage: "ellipsis", value: "More") {
          DetailsView()
            .toolbarBackground(.visible, for: .tabBar)
        }
      }
      .navigationTitle(selectedTab)
    }
  }
}

#Preview {
  ContentView()
}


