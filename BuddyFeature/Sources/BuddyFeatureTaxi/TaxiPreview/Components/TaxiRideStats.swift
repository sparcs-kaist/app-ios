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

  /// How long the taxi takes to reach the riders once it is called, which the route's driving time
  /// leaves out: the middle of the usual two to five minutes.
  private static let pickupWait: TimeInterval = 3.5 * 60

  var body: some View {
    // Rounded to the nearest minute, since the time is shown without seconds and would otherwise
    // always round down.
    let arrivesAt = departAt.addingTimeInterval(route.expectedTravelTime + Self.pickupWait)
    let arrival = Date(timeIntervalSinceReferenceDate: (arrivesAt.timeIntervalSinceReferenceDate / 60).rounded() * 60)
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
