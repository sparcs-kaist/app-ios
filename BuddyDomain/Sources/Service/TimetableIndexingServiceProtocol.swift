//
//  TimetableIndexingServiceProtocol.swift
//  BuddyDomain
//

import Foundation

/// Keeps the active timetable's events in Spotlight, where Siri reads them.
public protocol TimetableIndexingServiceProtocol: Sendable {
  /// Rebuilds the index from the active timetable. Bursts of calls are coalesced.
  func scheduleReindex()
  /// Removes everything indexed, e.g. on sign-out.
  func clear() async
}
