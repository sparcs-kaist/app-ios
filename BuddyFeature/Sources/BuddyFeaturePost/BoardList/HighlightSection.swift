//
//  HighlightSection.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 24/10/2026.
//

import SwiftUI
import BuddyDomain
import BuddyFeatureShared

/// A short list of posts above the boards, as on Ara's main page: the week's most viewed
/// (ranked), or the newest. Laid out like a chart in the App Store or Apple News: "See All" in
/// the header, rows separated by hairlines under the text, and no chevrons.
struct HighlightSection: View {
  let highlight: BoardHighlight
  let posts: [AraPost]
  let onSelect: (AraPost) -> Void

  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(alignment: .firstTextBaseline) {
        Label(highlight.title, systemImage: highlight.symbol)
          .font(.title2)
          .fontWeight(.bold)
        Spacer()
        seeAll
          .font(.body)
      }

      VStack(alignment: .leading, spacing: 0) {
        ForEach(Array(posts.enumerated()), id: \.element.id) { index, post in
          Button {
            onSelect(post)
          } label: {
            HighlightRow(rank: highlight.isRanked ? index + 1 : nil, post: post, showsBoard: highlight.board == nil)
          }
          .buttonStyle(.plain)
          .disabled(post.isHidden)

          if index < posts.count - 1 {
            Divider()
              // Starts under the title, past the rank.
              .padding(.leading, highlight.isRanked ? HighlightRow.rankWidth + HighlightRow.rankSpacing : 0)
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

  /// A board's section opens the board itself; the others, the whole list they preview.
  @ViewBuilder
  private var seeAll: some View {
    if let board = highlight.board {
      NavigationLink(value: board) {
        Text("See All", bundle: .module)
      }
    } else {
      NavigationLink {
        HighlightPostListView(highlight: highlight)
      } label: {
        Text("See All", bundle: .module)
      }
    }
  }
}

/// A post, ranked or not: its place beside its title, and where and when it was posted.
struct HighlightRow: View {
  let rank: Int?
  let post: AraPost
  /// Off in a board's own section, where every post is from that board.
  var showsBoard = true

  /// Wide enough for a single digit; the list never shows more than nine.
  static let rankWidth: CGFloat = 14
  static let rankSpacing: CGFloat = 12

  var body: some View {
    // Centred against the title and details, as in an App Store chart; on the title's baseline,
    // the larger digit rises above it.
    HStack(alignment: .center, spacing: Self.rankSpacing) {
      if let rank {
        Text(rank, format: .number)
          .font(.title3.weight(.bold).monospacedDigit())
          .fontDesign(.rounded)
          .foregroundStyle(Color.accentColor)
          .frame(width: Self.rankWidth)
      }

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
    if showsBoard, let board = post.board {
      parts.append(board.name.localized())
    }
    parts.append(post.createdAt.timeAgoDisplay)
    if post.commentCount > 0 {
      parts.append(String(localized: "\(post.commentCount) comments", bundle: .module))
    }
    return parts.joined(separator: " · ")
  }
}

/// What a highlight section shows, and how to load it.
enum BoardHighlight: Hashable {
  case trending
  /// The newest posts across these boards (all but Portal Notice, whose crawled notices would
  /// bury everyone else's, as on Ara's main page).
  case latest(boardIDs: [Int])
  /// The newest posts of one board, a section the reader added.
  case board(AraBoard)

  var title: String {
    switch self {
    case .trending: String(localized: "Trending", bundle: .module)
    case .latest: String(localized: "Latest", bundle: .module)
    case .board(let board): board.name.localized()
    }
  }

  var symbol: String {
    switch self {
    case .trending: "flame.fill"
    case .latest: "sparkles"
    case .board(let board): board.group.symbolName
    }
  }

  var isRanked: Bool { self == .trending }

  var board: AraBoard? {
    if case .board(let board) = self { board } else { nil }
  }

  var listType: PostListType {
    switch self {
    case .trending: .trending
    case .latest(let boardIDs): .latest(boardIDs: boardIDs)
    case .board(let board): .board(boardID: board.id)
    }
  }
}

extension AraBoardGroup {
  /// The group's symbol, for its header in the Boards list and its boards' sections.
  var symbolName: String {
    switch slug {
    case "notice": "bell.badge.fill"
    case "talk": "text.bubble.fill"
    case "club": "person.2.fill"
    case "trade": "tag.fill"
    case "communication": "envelope.open.fill"
    default: "list.clipboard"
    }
  }
}
