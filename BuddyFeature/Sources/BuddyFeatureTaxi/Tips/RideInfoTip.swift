//
//  RideInfoTip.swift
//  BuddyFeature
//

import SwiftUI
import TipKit

/// Under a taxi chat's title, saying that it opens the ride's info: where you mark your arrival and
/// luggage, call a taxi and see who is riding. Its button opens the info itself.
struct RideInfoTip: Tip {
  /// Identifies the tip's button, which opens the ride's info.
  static let openActionID = "open-ride-info"

  var title: Text { Text("Your Ride at a Glance", bundle: .module) }
  var message: Text? {
    Text("Tap the title to mark your arrival and luggage, call a taxi, or see who's riding.", bundle: .module)
  }
  var image: Image? { Image(systemName: "car.rear.fill") }
  var actions: [Action] {
    [Action(id: Self.openActionID, title: String(localized: "Open Ride Info", bundle: .module))]
  }
  var options: [any TipOption] { [Tips.MaxDisplayCount(3)] }
}
