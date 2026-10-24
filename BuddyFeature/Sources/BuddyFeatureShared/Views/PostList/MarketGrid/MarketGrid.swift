//
//  MarketGrid.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 24/10/2026.
//

import SwiftUI
import NukeUI
import BuddyDomain

/// The Market board as a grid of listings: photo, title and price, like a shop.
public struct MarketGrid: View {
  let posts: [AraPost]?
  var isLoadingMore: Bool = false
  var onRefresh: (() async -> Void)? = nil
  var onLoadMore: (() -> Void)? = nil
  /// Marks each photo as the source of a zoom transition into its post, keyed by post id.
  var transitionNamespace: Namespace.ID? = nil

  @State private var layout = MarketGridLayout.phone

  public init(
    posts: [AraPost]?,
    isLoadingMore: Bool = false,
    onRefresh: (() async -> Void)? = nil,
    onLoadMore: (() -> Void)? = nil,
    transitionNamespace: Namespace.ID? = nil
  ) {
    self.posts = posts
    self.isLoadingMore = isLoadingMore
    self.onRefresh = onRefresh
    self.onLoadMore = onLoadMore
    self.transitionNamespace = transitionNamespace
  }

  public var body: some View {
    if let posts, posts.isEmpty {
      ContentUnavailableView(
        String(localized: "Nothing Here Yet", bundle: .module),
        systemImage: "bag",
        description: Text("It looks like there are no posts on this page right now.", bundle: .module)
      )
    } else {
      ScrollView {
        LazyVGrid(columns: layout.columns, spacing: 20) {
          if let posts {
            ForEach(Array(posts.enumerated()), id: \.element.id) { index, post in
              cell(for: post)
                .onAppear {
                  let threshold = Int(Double(posts.count) * Constants.loadMoreThreshold)
                  if index >= threshold && !isLoadingMore {
                    onLoadMore?()
                  }
                }
            }
          } else {
            // Enough rows to fill the screen, whatever its size.
            let mocks = AraPost.mockList
            ForEach(0..<layout.placeholderCount, id: \.self) { index in
              MarketGridCell(post: mocks[index % mocks.count])
            }
            .redacted(reason: .placeholder)
          }
        }
        .padding(.leading, layout.leadingInset)
        .padding(.top, 8)
        .frame(maxWidth: .infinity, alignment: .leading)

        if isLoadingMore {
          ProgressView()
            .padding()
        }
      }
      .refreshable {
        await onRefresh?()
      }
      // Columns follow the measured width, and the fold when there is one.
      .onGeometryChange(for: MarketGridLayout.self) { proxy in
        MarketGridLayout(proxy: proxy)
      } action: { layout = $0 }
    }
  }

  @ViewBuilder
  private func cell(for post: AraPost) -> some View {
    if post.isHidden {
      MarketGridCell(post: post)
    } else {
      NavigationLink(value: post) {
        MarketGridCell(post: post, transitionNamespace: transitionNamespace)
      }
      .buttonStyle(.plain)
    }
  }
}

/// One listing: a square photo with its sale state, then the title and price.
struct MarketGridCell: View {
  let post: AraPost
  var transitionNamespace: Namespace.ID? = nil

  private var listing: AraMarketListing? { post.marketListing }
  private var isSold: Bool { listing?.state == .soldOut }
  private var isRead: Bool { post.readStatus == .read }

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      thumbnail
        .overlay(alignment: .topLeading) {
          if let label = listing?.stateLabel, !post.isHidden {
            Text(label)
              .font(.caption.weight(.semibold))
              .padding(.horizontal, 8)
              .padding(.vertical, 4)
              .glassEffect(.regular, in: .capsule)
              .padding(8)
          }
        }

      // Price first: it's what a shop grid is scanned for. The title then takes only the lines it
      // needs, so a short one leaves no gap; spare height falls below the card instead.
      VStack(alignment: .leading, spacing: 3) {
        if !post.isHidden {
          Text(listing?.formattedPrice ?? String(localized: "No Price", bundle: .module))
            .font(.headline)
            .foregroundStyle(listing?.price == nil || isSold ? .secondary : .primary)
            .strikethrough(isSold)
        }

        HStack(alignment: .firstTextBaseline, spacing: 4) {
          if post.readStatus == .updated {
            Circle()
              .fill(Color.accentColor)
              .frame(width: 7, height: 7)
              .accessibilityLabel(Text("Updated", bundle: .module))
          }
          Text(post.listTitle)
            .font(.subheadline)
            .foregroundStyle(post.isHidden || isRead ? .secondary : .primary)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
        }

        HStack(spacing: 6) {
          Text(post.createdAt.timeAgoDisplay)
          if post.commentCount > 0 {
            Label("\(post.commentCount)", systemImage: "bubble.right")
              .labelStyle(.titleAndIcon)
          }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(1)
      }
      .padding(.horizontal, 2)
    }
    .frame(maxHeight: .infinity, alignment: .top)
    .contentShape(.rect)
    .accessibilityElement(children: .combine)
  }

  private var thumbnail: some View {
    Color.clear
      .aspectRatio(1, contentMode: .fit)
      .overlay {
        if let url = post.thumbnailURL, !post.isHidden {
          LazyImage(url: url) { state in
            if let image = state.image {
              image
                .resizable()
                .scaledToFill()
            } else {
              placeholder(isLoading: state.error == nil)
            }
          }
        } else {
          placeholder(isLoading: false)
        }
      }
      .clipShape(.rect(cornerRadius: 14, style: .continuous))
      .saturation(isSold ? 0 : 1)
      .opacity(isSold ? 0.6 : 1)
      .modifier(ZoomSource(id: post.id, namespace: transitionNamespace))
  }

  private func placeholder(isLoading: Bool) -> some View {
    Rectangle()
      .fill(.fill.tertiary)
      .overlay {
        if !isLoading {
          Image(systemName: post.isHidden ? "eye.slash" : "bag")
            .font(.title)
            .foregroundStyle(.tertiary)
        }
      }
  }
}

/// The photo the post zooms out of, rounded like it is in the grid.
private struct ZoomSource: ViewModifier {
  let id: Int
  let namespace: Namespace.ID?

  func body(content: Content) -> some View {
    if let namespace {
      content.matchedTransitionSource(id: id, in: namespace) { source in
        source.clipShape(.rect(cornerRadius: 14, style: .continuous))
      }
    } else {
      content
    }
  }
}

/// Columns for the grid's width. Grids use every point rather than a reading-width column, and
/// on a foldable display the column count is even so the fold lands in a gutter; while the
/// device is partly folded, the middle gutter is widened to span the hinge exactly.
nonisolated struct MarketGridLayout: Equatable, Sendable {
  var columnWidths: [CGFloat]
  /// The gap after each column; the middle one spans the hinge when folded.
  var gaps: [CGFloat]
  var leadingInset: CGFloat
  /// The height the grid is shown in, for sizing the loading placeholder.
  var viewportHeight: CGFloat = 874

  static let phone = MarketGridLayout(width: 402, hinge: nil, hasHinge: false)

  private static let margin: CGFloat = 16
  private static let spacing: CGFloat = 12
  private static let idealWidth: CGFloat = 180

  /// Placeholder cells to fill the viewport: whole rows, rounding up so the last one runs off.
  var placeholderCount: Int {
    // A square photo, then at least 60 points of price, a title line and the date, then the row
    // gap. Underestimating only adds a row off-screen; overestimating would leave a gap.
    let rowHeight = (columnWidths.first ?? Self.idealWidth) + 60 + 20
    let rows = max(1, Int((viewportHeight / rowHeight).rounded(.up)))
    return rows * columnWidths.count
  }

  var columns: [GridItem] {
    zip(columnWidths, gaps).map { width, gap in
      GridItem(.fixed(width), spacing: gap, alignment: .top)
    }
  }

  init(width: CGFloat, hinge: CGRect?, hasHinge: Bool) {
    let margin = Self.margin, spacing = Self.spacing
    // A vertical fold band strictly inside the grid splits it into two halves.
    if let hinge, hinge.height > hinge.width, hinge.minX > margin, hinge.maxX < width - margin {
      let leftWidth = hinge.minX - margin
      let rightWidth = width - margin - hinge.maxX
      let perHalf = max(1, Int(((min(leftWidth, rightWidth) + spacing) / (Self.idealWidth + spacing)).rounded()))
      let columnWidth = (min(leftWidth, rightWidth) - CGFloat(perHalf - 1) * spacing) / CGFloat(perHalf)
      // Each half's columns hug the hinge-side edge of their half, so the gap is exactly the band.
      let leftUsed = CGFloat(perHalf) * columnWidth + CGFloat(perHalf - 1) * spacing
      columnWidths = Array(repeating: columnWidth, count: perHalf * 2)
      gaps = (0..<(perHalf * 2)).map { $0 == perHalf - 1 ? hinge.width : spacing }
      leadingInset = hinge.minX - leftUsed
      return
    }

    let available = max(width - margin * 2, 1)
    var count = max(2, Int(((available + spacing) / (Self.idealWidth + spacing)).rounded()))
    if hasHinge && !count.isMultiple(of: 2) {
      count += 1
    }
    let columnWidth = (available - CGFloat(count - 1) * spacing) / CGFloat(count)
    columnWidths = Array(repeating: columnWidth, count: count)
    gaps = Array(repeating: spacing, count: count)
    leadingInset = margin
  }

  init(proxy: GeometryProxy) {
    if #available(iOS 27.1, *) {
      let regions = proxy.reservedRegions(kind: .division, options: .includeInactive)
      let active = regions.first { $0.isActive }?.frame
      self.init(width: proxy.size.width, hinge: active, hasHinge: !regions.isEmpty)
    } else {
      self.init(width: proxy.size.width, hinge: nil, hasHinge: false)
    }
    viewportHeight = proxy.size.height
  }
}

#Preview {
  NavigationStack {
    MarketGrid(posts: nil)
  }
}
