//
//  PostListView.swift
//  soap
//
//  Created by Soongyu Kwon on 05/01/2025.
//

import SwiftUI

struct PostListView: View {
  @Namespace private var namespace

  @State private var searchText: String = ""
  @State private var showsComposeView: Bool = false

  private var viewModel = PostListViewModel()

  var body: some View {
    ZStack(alignment: .bottom) {
      List {
        ForEach(viewModel.postList) { post in
          PostListRow(post: post)
            .listRowSeparator(.hidden, edges: .top)
            .listRowSeparator(.visible, edges: .bottom)
        }
      }
      .listStyle(.plain)
    }
    .navigationTitle("General")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar(.hidden, for: .tabBar)
    .toolbar {
      ToolbarItem(placement: .bottomBar) {
        Label("Write", systemImage: "line.3.horizontal.decrease.circle")
      }

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
        .environment(viewModel)
        .padding(.top, 2)
        .presentationDragIndicator(.visible)
        .navigationTransition(.zoom(sourceID: "ComposeView", in: namespace))
    }
  }

  @ViewBuilder
  private var composeButton: some View {
    Button(action: {
      showsComposeView = true
    }, label: {
      HStack {
        Image(systemName: "pencil")
          .foregroundStyle(.indigo)
        Text("Write")
      }
      .padding()
      .padding(.horizontal, 4)
      .background(
        Capsule()
          .stroke(Color(UIColor.systemGray5), lineWidth: 1)
          .fill(.regularMaterial)
      )
    })
    .contentShape(Capsule())
    .tint(.primary)
    .shadow(color: .black.opacity(0.16), radius: 12)
  }
}

#Preview {
  NavigationStack {
    PostListView()
  }
}



