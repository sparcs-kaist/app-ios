//
//  FoldSplit.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 21/09/2026.
//

import SwiftUI

/// An active fold, expressed as the two-column geometry that keeps it in the
/// gutter: the leading column runs up to the fold, the gutter *is* the fold
/// band, and the trailing column takes the rest.
///
/// `nonisolated` and `Sendable` because it is produced inside a geometry
/// closure: a plain value type picks up a main-actor-isolated `Equatable`
/// conformance under `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` and then fails
/// to satisfy the `Sendable` requirement.
public nonisolated struct FoldSplit: Equatable, Sendable {
  /// Width of the leading column — the distance to the near edge of the fold.
  public let leadingWidth: CGFloat
  /// Gap between the columns, matching the fold band (40 pt on iPhone Duo).
  public let gutter: CGFloat

  /// Narrower than this and a column stops being worth keeping; the layout's
  /// usual split reads better than two slivers.
  private static let minimumColumnWidth: CGFloat = 240

  /// `nil` whenever the columns should keep their usual split: no fold, the
  /// device lying flat (inactive regions are not returned by default), a fold
  /// running *horizontally* across the layout — the inner display in portrait,
  /// where the band spans the full width and no column arrangement avoids it —
  /// or a fold so far off-centre that one column would be unusable.
  @available(iOS 27.1, *)
  public init?(proxy: GeometryProxy) {
    guard let fold = proxy.reservedRegions(kind: .division).first else { return nil }

    let band = fold.frame
    let width = proxy.size.width
    // `frame` already includes the clearance margins, so the columns only have
    // to stay outside it.
    guard band.minX > 0, band.maxX < width else { return nil }
    guard band.minX >= Self.minimumColumnWidth,
          width - band.maxX >= Self.minimumColumnWidth else { return nil }

    self.leadingWidth = band.minX
    self.gutter = band.width
  }
}

public extension View {
  /// Reports the active fold, as column geometry measured in this view's own
  /// bounds, so a two-column layout can put its gutter on the crease.
  ///
  /// The reader lives in a `background`, which is layout-neutral: it measures
  /// without disturbing the view's height inside a `ScrollView`. Region frames
  /// arrive in that proxy's coordinate space, which is the same space the
  /// column widths are expressed in.
  func foldSplit(_ split: Binding<FoldSplit?>) -> some View {
    background {
      if #available(iOS 27.1, *) {
        GeometryReader { proxy in
          Color.clear
            .onChange(of: FoldSplit(proxy: proxy), initial: true) { _, new in
              split.wrappedValue = new
            }
        }
      }
    }
  }
}
