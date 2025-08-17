//
//  FeedView.swift
//  soap
//
//  Created by Soongyu Kwon on 17/08/2025.
//

import SwiftUI
import Factory

struct FeedView: View {
  @Injected(\.authUseCase) private var authUseCase: AuthUseCaseProtocol
  @State private var showSettingsSheet: Bool = false

  var body: some View {
    NavigationStack {
      List {
        ForEach(0..<100) { _ in
          Text("hello")
        }
      }
      .listStyle(.plain)
      .navigationTitle("Feed")
      .toolbarTitleDisplayMode(.inlineLarge)
      .toolbar {
        ToolbarItem {
          Menu("More", systemImage: "ellipsis") {
            Button("Notifications", systemImage: "bell") { }

            Button("Settings", systemImage: "gear") {
              showSettingsSheet = true
            }

            Divider()

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

        ToolbarSpacer(.fixed)

        ToolbarItem {
          Button("Write", systemImage: "square.and.pencil") {

          }
        }
      }
      .sheet(isPresented: $showSettingsSheet) {
        SettingsView()
          .presentationDragIndicator(.visible)
      }
    }
  }
}

#Preview {
  FeedView()
}
