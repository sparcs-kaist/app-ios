//
//  FeedView.swift
//  soap
//
//  Created by Soongyu Kwon on 17/08/2025.
//

import SwiftUI
import Factory
import NukeUI

struct FeedView: View {
  @State private var viewModel: FeedViewModelProtocol = FeedViewModel()
  @Namespace private var namespace

  @State private var showSettingsSheet: Bool = false
  @State private var showComposeView: Bool = false

  var body: some View {
    NavigationStack {
      ScrollView {
        LazyVStack(spacing: 0) {
          switch viewModel.state {
          case .loading:
            ForEach(.constant(FeedPost.mockList)) { $post in
              FeedPostRow(post: $post)
                .padding(.vertical)

              Divider()
                .padding(.horizontal)
            }
            .redacted(reason: .placeholder)
          case .loaded:
            ForEach($viewModel.posts) { $post in
              FeedPostRow(post: $post)
                .padding(.vertical)

              Divider()
                .padding(.horizontal)
            }
          case .error(let message):
            ContentUnavailableView(
              "Error",
              systemImage: "questionmark.text.page",
              description: Text(message)
            )
          }
        }
      }
      .disabled(viewModel.state == .loading)
      .navigationTitle("Feed")
      .toolbarTitleDisplayMode(.inlineLarge)
      .task {
        await viewModel.fetchInitialData()
      }
      .toolbar {
        ToolbarItem {
          Button("Write", systemImage: "square.and.pencil") {
            showComposeView = true
          }
        }
        .matchedTransitionSource(id: "ComposeView", in: namespace)

        ToolbarSpacer(.fixed)
        
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
                try await viewModel.signOut()
              }
            }
          }
        }
      }
      .sheet(isPresented: $showSettingsSheet) {
        SettingsView()
          .presentationDragIndicator(.visible)
      }
      .sheet(isPresented: $showComposeView) {
        FeedPostComposeView()
          .navigationTransition(.zoom(sourceID: "ComposeView", in: namespace))
          .interactiveDismissDisabled()
      }
    }
  }
}



#Preview {
  FeedView()
}
