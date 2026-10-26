//
//  TaxiRouteStops.swift
//  BuddyFeature
//

import SwiftUI

/// Origin over destination, each marker pinned to its name's first line so long names can wrap.
/// The markers match the list card and the map pins: hollow for the origin, filled for the destination.
struct TaxiRouteStops: View {
  let source: String
  let destination: String

  @ScaledMetric(relativeTo: .title3) private var markerTop: CGFloat = 7

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .top, spacing: 12) {
        VStack(spacing: 0) {
          Circle()
            .strokeBorder(.secondary, lineWidth: 2.5)
            .frame(width: 11, height: 11)
          // Runs on past this row so it meets the destination marker.
          Rectangle()
            .fill(.tertiary)
            .frame(width: 2)
            .frame(maxHeight: .infinity)
            .padding(.vertical, 2)
            .padding(.bottom, -markerTop)
        }
        .padding(.top, markerTop)

        Text(source)
          .padding(.bottom, 8)
      }

      HStack(alignment: .top, spacing: 12) {
        Circle()
          .fill(.primary)
          .frame(width: 11, height: 11)
          .padding(.top, markerTop)

        Text(destination)
      }
    }
    .fixedSize(horizontal: false, vertical: true)
    .accessibilityElement(children: .combine)
  }
}

#Preview {
  TaxiRouteStops(source: "KAIST Main Campus", destination: "Government Complex Express Bus Terminal")
    .font(.title3.weight(.semibold))
    .frame(width: 300)
    .padding()
}
