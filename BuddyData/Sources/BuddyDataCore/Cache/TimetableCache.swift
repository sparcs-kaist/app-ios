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

  /// Returns the cached `Timetable` for the given key, or `nil` if not found.
  public func timetable(forKey key: String) -> Timetable? {
    read(forKey: key)
  }

  /// The last successfully fetched current timetable, even when semester lookup is offline.
  public func currentMyTable() -> Timetable? {
    timetable(forKey: "current-myTable")
  }

  public func storeCurrentMyTable(_ timetable: Timetable) {
    store(timetable, forKey: timetable.id)
    store(timetable, forKey: "current-myTable")
  }

  public func timetableList() -> [SemesterWithTimetables]? {
    read(forKey: "timetable-list")
  }

  public func storeTimetableList(_ list: [SemesterWithTimetables]) {
    write(list, forKey: "timetable-list")
  }

  public func semesters() -> [Semester]? { read(forKey: "semesters") }
  public func storeSemesters(_ semesters: [Semester]) { write(semesters, forKey: "semesters") }
  public func currentSemester() -> Semester? { read(forKey: "current-semester") }
  public func storeCurrentSemester(_ semester: Semester) { write(semester, forKey: "current-semester") }
  public func timetableSummaries(semester: Semester) -> [TimetableSummary]? {
    read(forKey: "\(semester.id)-summaries")
  }
  public func storeTimetableSummaries(_ summaries: [TimetableSummary], semester: Semester) {
    write(summaries, forKey: "\(semester.id)-summaries")
  }

  /// Keep saved navigation consistent after a confirmed rename or deletion.
  public func updateTimetableSummary(id: Int, title: String?) {
    let context = ModelContext(modelContainer)
    guard let records = try? context.fetch(FetchDescriptor<CachedTimetable>()) else { return }
    for record in records where record.cacheKey.hasSuffix("-summaries") {
      guard var summaries = try? JSONDecoder().decode([TimetableSummary].self, from: record.data),
            let index = summaries.firstIndex(where: { $0.id == id }) else { continue }
      if let title { summaries[index].title = title }
      else { summaries.remove(at: index) }
      guard let data = try? JSONEncoder().encode(summaries) else { continue }
      record.data = data
      record.updatedAt = .now
    }
    try? context.save()
  }

  public func state(semester: Semester?, timetableID: Int?) -> TimetableCachedState {
    let key = timetableID.map(String.init) ?? semester.map { "\($0.id)-myTable" }
    let table = key.flatMap { timetable(forKey: $0) }
    var updatedAt: Date?
    if table != nil, let key {
      let context = ModelContext(modelContainer)
      var descriptor = FetchDescriptor<CachedTimetable>(predicate: #Predicate { $0.cacheKey == key })
      descriptor.fetchLimit = 1
      updatedAt = try? context.fetch(descriptor).first?.updatedAt
    }
    return TimetableCachedState(semesters: semesters(), currentSemester: currentSemester(),
      timetables: semester.flatMap { timetableSummaries(semester: $0) },
      timetable: table, updatedAt: updatedAt)
  }

  private func read<Value: Decodable>(forKey key: String) -> Value? {
    let context = ModelContext(modelContainer)
    var descriptor = FetchDescriptor<CachedTimetable>(
      predicate: #Predicate { $0.cacheKey == key }
    )
    descriptor.fetchLimit = 1

    guard let cached = try? context.fetch(descriptor).first else { return nil }

    return try? JSONDecoder().decode(Value.self, from: cached.data)
  }

  // MARK: - Write

  /// Persists a `Timetable` under the given key, inserting or updating as needed.
  public func store(_ timetable: Timetable, forKey key: String) {
    write(timetable, forKey: key)
  }

  private func write<Value: Encodable>(_ value: Value, forKey key: String) {
    guard let data = try? JSONEncoder().encode(value) else { return }

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
	
	/// Removes all cached timetable entries.
	public func clear() {
		let context = ModelContext(modelContainer)
		try? context.delete(model: CachedTimetable.self)
		try? context.save()
	}
}
