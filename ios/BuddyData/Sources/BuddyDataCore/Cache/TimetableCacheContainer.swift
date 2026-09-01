//
//  TimetableCacheContainer.swift
//  BuddyData
//
//  Created by Claude on 11/03/2026.
//

import Foundation
import SwiftData

/// Holds the shared ModelContainer used for timetable caching.
/// Set this once at app launch before any use-case is resolved.
public enum TimetableCacheContainer {
  nonisolated(unsafe) public static var shared: ModelContainer?
}
