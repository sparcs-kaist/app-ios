//
//  PostListView.swift
//  soap
//
//  Created by Soongyu Kwon on 05/01/2025.
//

import SwiftUI

struct PostListView: View {
  @State private var viewModel: PostListViewModelProtocol

  @State private var showsComposeView: Bool = false
  @Namespace private var namespace

  init(board: AraBoard) {
    _viewModel = State(initialValue: PostListViewModel(board: board))
  }

  var body: some View {
    ZStack(alignment: .bottom) {
      List {
        switch viewModel.state {
        case .loading:
          ProgressView()
        case .loaded:
          ForEach(viewModel.postList) { post in
            PostListRow(post: post)
              .listRowSeparator(.hidden, edges: .top)
              .listRowSeparator(.visible, edges: .bottom)
          }
        case .error(let message):
          ContentUnavailableView("Error", systemImage: "wifi.exclamationmark", description: Text(message))
        }
      }
      .listStyle(.plain)
    }
    .navigationTitle(viewModel.board.name.localized())
    .navigationBarTitleDisplayMode(.inline)
    .toolbar(.hidden, for: .tabBar)
    .toolbar {
      ToolbarSpacer(.flexible, placement: .bottomBar)

      ToolbarItem(placement: .bottomBar) {
        Button("Write", systemImage: "square.and.pencil") {
          showsComposeView = true
        }
      }
      .matchedTransitionSource(id: "ComposeView", in: namespace)
    }
    .sheet(isPresented: $showsComposeView) {
      PostComposeView()
        .interactiveDismissDisabled()
        .navigationTransition(.zoom(sourceID: "ComposeView", in: namespace))
    }
  }
}

#Preview {
  NavigationStack {
    PostListView(board: AraBoard.mock)
  }
}



