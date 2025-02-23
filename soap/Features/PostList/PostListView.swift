//
//  PostListView.swift
//  soap
//
//  Created by Soongyu Kwon on 05/01/2025.
//

import SwiftUI

struct PostListView: View {
  @State private var searchText: String = ""
  @State private var showsComposeView: Bool = false

  private var viewModel = PostListViewModel()

  init() {
    let appearance = UINavigationBarAppearance()
    appearance.configureWithTransparentBackground()

    // Add a blur effect to mimic Material.bar
    let blurEffect = UIBlurEffect(style: .systemMaterial)
    let blurEffectView = UIVisualEffectView(effect: blurEffect)
    blurEffectView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UINavigationBar.appearance().frame.height)

    // Create a custom background view and set it
    let backgroundImage = UIGraphicsImageRenderer(size: blurEffectView.bounds.size).image { _ in
      blurEffectView.layer.render(in: UIGraphicsGetCurrentContext()!)
    }
    appearance.backgroundImage = backgroundImage

    // Remove the shadow
    appearance.shadowColor = .clear

    // Apply the appearance
    UINavigationBar.appearance().standardAppearance = appearance
    UINavigationBar.appearance().scrollEdgeAppearance = appearance
  }

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

      composeButton
    }
    .navigationTitle("General")
    .navigationBarTitleDisplayMode(.inline)
    .safeAreaInset(edge: .top) {
      ZStack(alignment: .bottom) {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack {
            Text("All")
              .font(.subheadline)
              .padding(6)
              .padding(.horizontal, 4)
              .background(
                Capsule()
                  .stroke(Color(UIColor.systemGray5), lineWidth: 1)
                  .fill(.black)
              )
              .foregroundStyle(.white)

            ForEach(viewModel.flairList, id: \.self) { flair in
              Text(flair)
                .font(.subheadline)
                .padding(6)
                .padding(.horizontal, 4)
                .background(
                  Capsule()
                    .stroke(Color(UIColor.systemGray5), lineWidth: 1)
                    .fill(Color(UIColor.systemGray6))
                )
            }
          }
          .tint(.primary)
          .padding([.horizontal, .bottom])
          .padding(.top, 8)
        }

        Rectangle()
          .fill(Color(UIColor.systemGray5))
          .frame(height: 1)
      }
      .background(.bar)
    }
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        Button(action: {

        }) {
          Image(systemName: "magnifyingglass")
        }
        .tint(.primary)
      }
    }
    .sheet(isPresented: $showsComposeView) {
      PostComposeView()
        .environment(viewModel)
        .presentationDragIndicator(.visible)
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



