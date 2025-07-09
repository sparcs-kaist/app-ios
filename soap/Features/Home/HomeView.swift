//
//  HomeView.swift
//  soap
//
//  Created by Soongyu Kwon on 12/06/2025.
//

import SwiftUI
import Factory

struct HomeView: View {
  @Injected(\.authUseCase) private var authUseCase: AuthUseCaseProtocol

  var body: some View {
    NavigationStack {
      ScrollView {
        LazyVStack(spacing: 27) {
          BoardRecentSection(title: "Trending")

          TaxiRecentSection()

          BoardsSection()

          BoardRecentSection(title: "General")

          BoardRecentSection(title: "Notice")
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
            Button("Sign Out", systemImage: "rectangle.portrait.and.arrow.right") {
              Task {
                try await authUseCase.signOut()
              }
            }
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
