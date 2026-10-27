//
//  TaxiRiderCluster.swift
//  BuddyFeature
//

import SwiftUI
import BuddyDomain
import BuddyFeatureShared

/// The riders' photos packed into one circle, the way Messages shows a group. Riders are grey until
/// they arrive, and arrived riders take the larger places, so the cluster grows as people turn up.
struct TaxiRiderCluster: View {
  let riders: [TaxiParticipant]
  let size: CGFloat

  /// Centre and diameter of each photo, as fractions of the circle, by rider count.
  private var layout: [(x: CGFloat, y: CGFloat, d: CGFloat)] {
    switch riders.count {
    case 0, 1: [(0.5, 0.5, 0.84)]
    case 2: [(0.38, 0.38, 0.56), (0.72, 0.72, 0.4)]
    case 3: [(0.4, 0.38, 0.54), (0.78, 0.56, 0.34), (0.46, 0.8, 0.3)]
    default: [(0.38, 0.36, 0.5), (0.77, 0.36, 0.32), (0.68, 0.74, 0.28), (0.33, 0.76, 0.24)]
    }
  }

  private var ordered: [TaxiParticipant] {
    riders.filter(\.isArrived) + riders.filter { !$0.isArrived }
  }

  var body: some View {
    ZStack(alignment: .topLeading) {
      ForEach(Array(zip(ordered.prefix(4), layout)), id: \.0.id) { rider, slot in
        TaxiProfilePhoto(url: rider.profileImageURL)
          .frame(width: size * slot.d, height: size * slot.d)
          .saturation(rider.isArrived ? 1 : 0)
          .opacity(rider.isArrived ? 1 : 0.55)
          .position(x: size * slot.x, y: size * slot.y)
      }
    }
    .frame(width: size, height: size)
    .background(.fill.secondary, in: .circle)
    .animation(.spring(duration: 0.5, bounce: 0.3), value: ordered.map(\.id))
    .accessibilityHidden(true)
  }
}
