//
//  TaxiRouteStops.swift
//  BuddyFeature
//

import SwiftUI
import UIKit

/// Origin over destination, joined by a line: the origin carries the same location symbol as its
/// pin on the preview map, the destination a filled dot. Each marker is centred on its name's
/// first line, so names can wrap and the markers still sit level with the text.
public struct TaxiRouteStops: View {
  let source: String
  let destination: String
  let textStyle: Font.TextStyle
  let weight: Font.Weight
  let markerSize: CGFloat
  let rowSpacing: CGFloat

  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  @Environment(\.colorScheme) private var colorScheme

  public init(
    source: String,
    destination: String,
    textStyle: Font.TextStyle = .body,
    weight: Font.Weight = .medium,
    markerSize: CGFloat = 12,
    rowSpacing: CGFloat = 6
  ) {
    self.source = source
    self.destination = destination
    self.textStyle = textStyle
    self.weight = weight
    self.markerSize = markerSize
    self.rowSpacing = rowSpacing
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: rowSpacing) {
      row(source, isDestination: false)
      row(destination, isDestination: true)
    }
    .font(.system(textStyle, weight: weight))
    .overlayPreferenceValue(MarkerBounds.self) { markers in
      // One line between the two markers, however many lines the names take.
      GeometryReader { proxy in
        if let origin = markers[false], let end = markers[true] {
          let from = proxy[origin]
          let to = proxy[end]
          // Solid colours rather than the hierarchical styles: on a dark card's glass those turn
          // translucent, leaving the dot and line grey beside the solid location symbol.
          Rectangle()
            .fill(colorScheme == .dark ? Color.white : Color(uiColor: .tertiaryLabel))
            .frame(width: 2, height: max(to.minY - from.maxY - 4, 0))
            .position(x: from.midX, y: (from.maxY + to.minY) / 2)
        }
      }
    }
    .fixedSize(horizontal: false, vertical: true)
    .accessibilityElement(children: .combine)
  }

  private func row(_ name: String, isDestination: Bool) -> some View {
    HStack(alignment: .firstTextBaseline, spacing: markerSize / 2) {
      marker(isDestination: isDestination)
        .anchorPreference(key: MarkerBounds.self, value: .bounds) { [isDestination: $0] }
        // Centre the marker half a cap height above the baseline, the visual middle of a line
        // of Latin capitals and of Hangul alike.
        .alignmentGuide(.firstTextBaseline) { $0[VerticalAlignment.center] + capHeight / 2 }
        .accessibilityHidden(true)

      Text(name)
    }
  }

  @ViewBuilder
  private func marker(isDestination: Bool) -> some View {
    if isDestination {
      // A filled circle as large as the symbol's reads heavier, so it is drawn smaller and
      // centred in the same space.
      Circle()
        .fill(colorScheme == .dark ? Color.white : Color.black)
        .frame(width: markerSize * 0.7, height: markerSize * 0.7)
        .frame(width: markerSize, height: markerSize)
    } else {
      Image(systemName: "location.circle.fill")
        .resizable()
        .scaledToFit()
        .foregroundStyle(.primary)
        .frame(width: markerSize, height: markerSize)
    }
  }

  /// Cap height of the text style at the current Dynamic Type size.
  private var capHeight: CGFloat {
    let traits = UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory(dynamicTypeSize))
    return UIFont.preferredFont(forTextStyle: UIFont.TextStyle(textStyle), compatibleWith: traits).capHeight
  }

  private struct MarkerBounds: PreferenceKey {
    static let defaultValue: [Bool: Anchor<CGRect>] = [:]
    static func reduce(value: inout [Bool: Anchor<CGRect>], nextValue: () -> [Bool: Anchor<CGRect>]) {
      value.merge(nextValue()) { $1 }
    }
  }
}

private extension UIFont.TextStyle {
  init(_ style: Font.TextStyle) {
    switch style {
    case .extraLargeTitle: self = .extraLargeTitle
    case .extraLargeTitle2: self = .extraLargeTitle2
    case .largeTitle: self = .largeTitle
    case .title: self = .title1
    case .title2: self = .title2
    case .title3: self = .title3
    case .headline: self = .headline
    case .subheadline: self = .subheadline
    case .callout: self = .callout
    case .footnote: self = .footnote
    case .caption: self = .caption1
    case .caption2: self = .caption2
    default: self = .body
    }
  }
}

#Preview {
  VStack(alignment: .leading, spacing: 32) {
    TaxiRouteStops(source: "대전역", destination: "카이스트 본원")
    TaxiRouteStops(
      source: "KAIST Main Campus",
      destination: "Government Complex Express Bus Terminal",
      textStyle: .title3,
      weight: .semibold,
      markerSize: 14,
      rowSpacing: 8
    )
  }
  .frame(width: 280)
  .padding()
}
