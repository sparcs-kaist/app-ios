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
///
/// On a phone the shelf runs to the screen's edges, with the next card peeking in. Where the
/// list is a column narrower than the screen (iPad, iPhone Duo's inner display), it would be cut
/// off mid-card at the column's edge, so there it shows whole cards that fill the column, drawn
/// unclipped, and cards fade and shrink as they scroll out past its edges.
struct MarketShelf: View {
  let board: AraBoard
  let posts: [AraPost]
  let onSelect: (AraPost) -> Void

  private static let cardWidth: CGFloat = 150
  private static let spacing: CGFloat = 12
  private static let margin: CGFloat = 16

  @State private var width: CGFloat = 0
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass

  /// Whether the shelf sits in a column rather than spanning the screen.
  private var isInColumn: Bool {
    horizontalSizeClass == .regular
  }

  /// Whole cards across the column, each as close to the phone's width as fits.
  private var columnCardWidth: CGFloat {
    let available = isInColumn ? width : width - Self.margin * 2
    let count = max(2, ((available + Self.spacing) / (Self.cardWidth + Self.spacing)).rounded())
    return (available - Self.spacing * (count - 1)) / count
  }

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
        LazyHStack(alignment: .top, spacing: Self.spacing) {
          ForEach(posts) { post in
            Button {
              onSelect(post)
            } label: {
              MarketGridCell(post: post, titleLineLimit: 1)
                .frame(width: isInColumn && width > 0 ? columnCardWidth : Self.cardWidth)
            }
            .buttonStyle(.plain)
            .disabled(post.isHidden)
            // Leaving the column: fully faded once a card is all the way out.
            .scrollTransition(.interactive(timingCurve: .linear), axis: .horizontal) { card, phase in
              let out = isInColumn ? min(abs(phase.value), 1) : 0
              return card
                .opacity(1 - out)
                .scaleEffect(1 - out * 0.3, anchor: phase.value < 0 ? .trailing : .leading)
            }
          }
        }
        .scrollTargetLayout()
      }
      .scrollTargetBehavior(.viewAligned)
      .scrollIndicators(.hidden)
      // Cards run to the screen's edges as they scroll, while the first lines up with the headers.
      // On a phone the cards run under the margins to the screen's edges. In a column they fill
      // it exactly and are drawn past its edges, where the transition above fades them out.
      .contentMargins(.horizontal, isInColumn ? 0 : Self.margin, for: .scrollContent)
      .scrollClipDisabled(isInColumn)
      .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
      .padding(.horizontal, isInColumn ? 0 : -Self.margin)
    }
  }
}
