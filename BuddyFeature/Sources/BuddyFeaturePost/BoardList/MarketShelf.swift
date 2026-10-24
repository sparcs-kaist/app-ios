//
//  MarketShelf.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 24/10/2026.
//

import SwiftUI
import BuddyDomain
import BuddyFeatureShared

/// The newest Market listings as a shelf of cards, scrolling sideways like a row in the App
/// Store, with the board itself a tap away.
struct MarketShelf: View {
  let board: AraBoard
  let posts: [AraPost]
  let onSelect: (AraPost) -> Void

  private static let cardWidth: CGFloat = 150

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(alignment: .firstTextBaseline) {
        Label(board.name.localized(), systemImage: "bag.fill")
          .font(.title2)
          .fontWeight(.bold)
        Spacer()
        NavigationLink(value: board) {
          Text("See All", bundle: .module)
            .font(.body)
        }
      }

      ScrollView(.horizontal) {
        LazyHStack(alignment: .top, spacing: 12) {
          ForEach(posts) { post in
            Button {
              onSelect(post)
            } label: {
              MarketGridCell(post: post)
                .frame(width: Self.cardWidth)
            }
            .buttonStyle(.plain)
            .disabled(post.isHidden)
          }
        }
        .scrollTargetLayout()
      }
      .scrollTargetBehavior(.viewAligned)
      .scrollIndicators(.hidden)
      // Cards run to the screen's edges as they scroll, while the first lines up with the headers.
      .contentMargins(.horizontal, 16, for: .scrollContent)
      .padding(.horizontal, -16)
    }
  }
}
