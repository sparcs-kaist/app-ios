//
//  TaxiRideStats.swift
//  BuddyFeature
//

import SwiftUI
import MapKit

/// The ride's estimated arrival, driving time and distance, from the calculated route. Until the
/// route arrives it shows a placeholder of the same size, so the sheet's layout doesn't shift
/// when the figures come in.
struct TaxiRideStats: View {
  let departAt: Date
  let route: MKRoute?

  /// Stands in for the figures while the route loads: a typical ride's, only ever shown redacted.
  private static let placeholderTravelTime: TimeInterval = 18 * 60
  private static let placeholderDistance: CLLocationDistance = 8_900

  /// How long the taxi takes to reach the riders once it is called, which the route's driving time
  /// leaves out: the middle of the usual two to five minutes.
  private static let pickupWait: TimeInterval = 3.5 * 60

  var body: some View {
    // Rounded to the nearest minute, since the time is shown without seconds and would otherwise
    // always round down.
    let travelTime = route?.expectedTravelTime ?? Self.placeholderTravelTime
    let distance = route?.distance ?? Self.placeholderDistance
    let arrivesAt = departAt.addingTimeInterval(travelTime + Self.pickupWait)
    let arrival = Date(timeIntervalSinceReferenceDate: (arrivesAt.timeIntervalSinceReferenceDate / 60).rounded() * 60)
      .formatted(date: .omitted, time: .shortened)

    HStack(spacing: 18) {
      Label("~\(arrival)", systemImage: "flag.pattern.checkered")
        .accessibilityLabel(Text("Arrives around \(arrival)", bundle: .module))
      Label(
        Duration.seconds(travelTime)
          .formatted(.units(allowed: [.hours, .minutes], width: .abbreviated)),
        systemImage: "car.fill"
      )
      Label(
        Measurement(value: distance, unit: UnitLength.meters)
          .formatted(.measurement(width: .abbreviated, usage: .road)),
        systemImage: "point.topleft.down.to.point.bottomright.curvepath"
      )
    }
    .font(.subheadline.weight(.medium))
    .foregroundStyle(.secondary)
    .lineLimit(1)
    .redacted(reason: route == nil ? .placeholder : [])
    .accessibilityHidden(route == nil)
    .animation(.easeInOut(duration: 0.25), value: route == nil)
  }
}
