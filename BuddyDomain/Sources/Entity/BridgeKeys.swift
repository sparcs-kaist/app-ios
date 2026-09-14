//
//  BridgeKeys.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 06/10/2025.
//

import Foundation

public enum BridgeKeys {
  public static let timetable = "timetable"
  /// The whole theme, not just its id: a user's own theme only exists on the
  /// phone, so the watch can't resolve an id it has never seen.
  public static let timetableTheme = "timetableTheme"
}
