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
  /// Width of the trailing column — from the far edge of the fold to the end.
  public let trailingWidth: CGFloat

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
    self.trailingWidth = width - band.maxX
  }
}

public extension View {
  /// Reports the active fold, as column geometry measured in this view's own
  /// bounds, so a two-column layout can put its gutter on the crease.
  ///
  /// Measured with `onGeometryChange`, which runs again whenever the reserved
  /// regions change, including when the device folds without changing size.
  /// Region frames arrive in this view's coordinate space, which is the same
  /// space the column widths are expressed in.
  func foldSplit(_ split: Binding<FoldSplit?>) -> some View {
    onGeometryChange(for: FoldSplit?.self) { proxy in
      if #available(iOS 27.1, *) {
        FoldSplit(proxy: proxy)
      } else {
        nil
      }
    } action: { new in
      split.wrappedValue = new
    }
  }

  /// Keeps this view's content off an active vertical fold by confining it to
  /// the wider side of the crease, such as a search field, a filter bar or a
  /// comment field that would otherwise span the hinge.
  ///
  /// Apply it to a view that spans the screen's width, such as the outer frame
  /// of `contentWidth()`: the content is inset by padding, so the measured
  /// width stays the whole screen's and the fold is never measured against the
  /// inset content. With no active fold, as on every iPhone and iPad, nothing
  /// changes.
  func avoidingFold() -> some View {
    modifier(FoldAvoidance())
  }
}

private struct FoldAvoidance: ViewModifier {
  @State private var split: FoldSplit?

  func body(content: Content) -> some View {
    content
      .padding(.leading, leadingInset)
      .padding(.trailing, trailingInset)
      .foldSplit($split)
      .animation(.snappy, value: split)
  }

  private var keepsLeadingSide: Bool {
    guard let split else { return true }
    return split.leadingWidth >= split.trailingWidth
  }

  private var leadingInset: CGFloat {
    guard let split, !keepsLeadingSide else { return 0 }
    return split.leadingWidth + split.gutter
  }

  private var trailingInset: CGFloat {
    guard let split, keepsLeadingSide else { return 0 }
    return split.gutter + split.trailingWidth
  }
}
