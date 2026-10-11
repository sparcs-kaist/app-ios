//
//  BuddyAppIntentsPackage.swift
//  soap
//

import AppIntents
import BuddyIntents

/// Pulls the Siri timetable intents and entities in `BuddyIntents` into the app's
/// App Intents metadata.
struct BuddyAppIntentsPackage: AppIntentsPackage {
  static var includedPackages: [any AppIntentsPackage.Type] {
    [BuddyIntentsPackage.self]
  }
}
