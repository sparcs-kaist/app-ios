//
//  HomeView.swift
//  soap
//
//  Created by Soongyu Kwon on 12/06/2025.
//

import SwiftUI

struct HomeView: View {
  var body: some View {
    NavigationStack {
      ScrollView {
        LazyVStack(spacing: 27) {
          GeneralRecentSection()

          TaxiRecentSection()
        }
        .padding(.vertical)
      }
      .navigationTitle(Text("Home"))
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem {
          Button("Notifications", systemImage: "bell") { }
        }

        ToolbarSpacer(.fixed)

        ToolbarItem {
          Menu("More", systemImage: "ellipsis") {
            Button("Settings", systemImage: "gear") { }
          }
        }
      }
      .background(Color.secondarySystemBackground)
    }
  }
}

#Preview {
  HomeView()
}
