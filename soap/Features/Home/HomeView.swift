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
  @State private var showSettingsSheet: Bool = false

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
            Button("Settings", systemImage: "gear") {
                showSettingsSheet = true
            }

            Button(
              "Sign Out",
              systemImage: "rectangle.portrait.and.arrow.right",
              role: .destructive
            ) {
              Task {
                try await authUseCase.signOut()
              }
            }
          }
        }
      }
      .background(Color.secondarySystemBackground)
      .sheet(isPresented: $showSettingsSheet) {
        SettingsView()
          .presentationDragIndicator(.visible)
      }
    }
  }
}

#Preview {
  HomeView()
}
