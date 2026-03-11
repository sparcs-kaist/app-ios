//
//  TimetableCache.swift
//  BuddyData
//
//  Created by Claude on 11/03/2026.
//

import Foundation
import SwiftData
import BuddyDomain

/// Thread-safe cache that reads/writes ``CachedTimetable`` records from SwiftData.
public final class TimetableCache: Sendable {
  private let modelContainer: ModelContainer

  public init(modelContainer: ModelContainer) {
    self.modelContainer = modelContainer
  }

  // MARK: - Read

  /// Returns the cached `V2Timetable` for the given key, or `nil` if not found.
  public func timetable(forKey key: String) -> V2Timetable? {
    let context = ModelContext(modelContainer)
    var descriptor = FetchDescriptor<CachedTimetable>(
      predicate: #Predicate { $0.cacheKey == key }
    )
    descriptor.fetchLimit = 1

    guard let cached = try? context.fetch(descriptor).first else { return nil }

    return try? JSONDecoder().decode(V2Timetable.self, from: cached.data)
  }

  // MARK: - Write

  /// Persists a `V2Timetable` under the given key, inserting or updating as needed.
  public func store(_ timetable: V2Timetable, forKey key: String) {
    guard let data = try? JSONEncoder().encode(timetable) else { return }

    let context = ModelContext(modelContainer)
    var descriptor = FetchDescriptor<CachedTimetable>(
      predicate: #Predicate { $0.cacheKey == key }
    )
    descriptor.fetchLimit = 1

    if let existing = try? context.fetch(descriptor).first {
      existing.data = data
      existing.updatedAt = .now
    } else {
      context.insert(CachedTimetable(cacheKey: key, data: data))
    }

    try? context.save()
  }

  // MARK: - Invalidate

  /// Removes the cached entry for the given key.
  public func invalidate(key: String) {
    let context = ModelContext(modelContainer)
    var descriptor = FetchDescriptor<CachedTimetable>(
      predicate: #Predicate { $0.cacheKey == key }
    )
    descriptor.fetchLimit = 1

    guard let existing = try? context.fetch(descriptor).first else { return }
    context.delete(existing)
    try? context.save()
  }
}
