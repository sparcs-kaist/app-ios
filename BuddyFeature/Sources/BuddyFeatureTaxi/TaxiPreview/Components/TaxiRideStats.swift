//
//  TaxiRideStats.swift
//  BuddyFeature
//

import SwiftUI
import MapKit

/// The ride's estimated arrival, driving time and distance, from the calculated route.
struct TaxiRideStats: View {
  let departAt: Date
  let route: MKRoute

  var body: some View {
    let arrival = departAt
      .addingTimeInterval(route.expectedTravelTime)
      .formatted(date: .omitted, time: .shortened)

    HStack(spacing: 18) {
      Label("~\(arrival)", systemImage: "flag.pattern.checkered")
        .accessibilityLabel(Text("Arrives around \(arrival)", bundle: .module))
      Label(
        Duration.seconds(route.expectedTravelTime)
          .formatted(.units(allowed: [.hours, .minutes], width: .abbreviated)),
        systemImage: "car.fill"
      )
      Label(
        Measurement(value: route.distance, unit: UnitLength.meters)
          .formatted(.measurement(width: .abbreviated, usage: .road)),
        systemImage: "point.topleft.down.to.point.bottomright.curvepath"
      )
    }
    .font(.subheadline.weight(.medium))
    .foregroundStyle(.secondary)
    .lineLimit(1)
  }
}
