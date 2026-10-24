//
//  TrendingSection.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 24/10/2026.
//

import SwiftUI
import BuddyDomain
import BuddyFeatureShared

/// The week's most viewed posts at the top of the Boards list, ranked as on Ara's main page.
/// Laid out like a chart in the App Store or Apple News: "See All" in the header, rows
/// separated by hairlines under the text, and no chevrons.
struct TrendingSection: View {
  let posts: [AraPost]
  let onSelect: (AraPost) -> Void

  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(alignment: .firstTextBaseline) {
        Label(String(localized: "Trending", bundle: .module), systemImage: "flame.fill")
          .font(.title2)
          .fontWeight(.bold)
        Spacer()
        NavigationLink {
          TrendingPostListView()
        } label: {
          Text("See All", bundle: .module)
            .font(.body)
        }
      }

      VStack(alignment: .leading, spacing: 0) {
        ForEach(Array(posts.enumerated()), id: \.element.id) { index, post in
          Button {
            onSelect(post)
          } label: {
            TrendingRow(rank: index + 1, post: post)
          }
          .buttonStyle(.plain)
          .disabled(post.isHidden)

          if index < posts.count - 1 {
            Divider()
              // Starts under the title, past the rank.
              .padding(.leading, TrendingRow.rankWidth + TrendingRow.rankSpacing)
          }
        }
      }
      .padding(.horizontal)
      .padding(.vertical, 4)
      .glassEffect(
        colorScheme == .light ? .identity : .regular.interactive(),
        in: .rect(cornerRadius: 28)
      )
      .background(colorScheme == .light ? Color.secondarySystemGroupedBackground : .clear, in: .rect(cornerRadius: 28))
    }
  }
}

/// A ranked post: its place beside its title, and where and when it was posted.
struct TrendingRow: View {
  let rank: Int
  let post: AraPost

  /// Wide enough for a single digit; the list never shows more than nine.
  static let rankWidth: CGFloat = 14
  static let rankSpacing: CGFloat = 12

  var body: some View {
    // Centred against the title and details, as in an App Store chart; on the title's baseline,
    // the larger digit rises above it.
    HStack(alignment: .center, spacing: Self.rankSpacing) {
      Text(rank, format: .number)
        .font(.title3.weight(.bold).monospacedDigit())
        .fontDesign(.rounded)
        .foregroundStyle(Color.accentColor)
        .frame(width: Self.rankWidth)

      VStack(alignment: .leading, spacing: 2) {
        Text(post.listTitle)
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(post.isHidden ? .secondary : .primary)
          .lineLimit(1)

        Text(details)
          .font(.footnote)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(.vertical, 10)
    .contentShape(.rect)
    .accessibilityElement(children: .combine)
  }

  /// "Wanted · 4 days ago · 12 comments", leaving out what's missing.
  private var details: String {
    var parts = [String]()
    if let board = post.board {
      parts.append(board.name.localized())
    }
    parts.append(post.createdAt.timeAgoDisplay)
    if post.commentCount > 0 {
      parts.append(String(localized: "\(post.commentCount) comments", bundle: .module))
    }
    return parts.joined(separator: " · ")
  }
}
