//
//  TimetableEntityIndexer.swift
//  BuddyIntents
//

import Foundation
import OSLog
import CoreSpotlight
import Synchronization
import AppIntents
import BuddyDomain
import BuddyDataCore

/// Mirrors the active timetable's events and lectures into Spotlight, where Siri
/// answers schedule questions from. Indexing happens on iOS 27 only.
///
/// Rebuilds and clears run one at a time, in order, so a rebuild can't interleave
/// with another or land after sign-out's clear. A rebuild never runs signed out,
/// so a refresh that finishes after sign-out can't put the old schedule back.
public final class TimetableEntityIndexer: TimetableIndexingServiceProtocol {
  private let queue = SerialTaskQueue()
  private let pending = Mutex<Task<Void, Never>?>(nil)

  public init() {}

  public func scheduleReindex() {
    guard #available(iOS 27.0, *) else { return }
    pending.withLock { task in
      task?.cancel()
      // A selection change and the refresh it triggers arrive together; index once.
      task = Task { [queue] in
        try? await Task.sleep(for: .seconds(1))
        guard !Task.isCancelled else { return }
        await queue.run { await Self.reindex() }
      }
    }
  }

  public func clear() async {
    pending.withLock { task in
      task?.cancel()
      task = nil
    }
    guard #available(iOS 27.0, *) else { return }
    // Queued behind any rebuild already running, so it wipes whatever that wrote.
    await queue.run {
      try? await Self.removeAll(from: Self.index)
    }
  }

  /// Unreadable while the device is locked: it holds the user's schedule.
  private static var index: CSSearchableIndex {
    CSSearchableIndex(name: "buddy.timetable", protectionClass: .complete)
  }

  /// Replaces the index with the active timetable, read from the cache the app
  /// has just refreshed. The set is small, so a full replace is simplest.
  @available(iOS 27.0, *)
  static func reindex() async {
    guard isSignedIn,
          let cache = TimetableCacheContainer.makeCache(),
          let active = await ActiveTimetableResolver(useCase: CachedTimetableUseCase(cache: cache)).resolve(),
          isSignedIn else {
      logger.debug("Reindex skipped: signed out or no active timetable")
      return
    }
    let index = Self.index
    let events = ClassEventEntity.all(for: active)
    let lectures = LectureEntity.all(for: active)
    logger.debug("""
      Reindexing \(String(describing: active.source), privacy: .private): \
      \(active.timetable.lectures.count) lectures, \(active.timetable.activities.count) activities, \
      \(events.count) events
      """)
    do {
      try await removeAll(from: index)
      try await index.indexAppEntities(events)
      try await index.indexAppEntities(lectures)
    } catch {
      // Spotlight is best-effort; the next timetable change reindexes again.
      logger.error("Reindex failed: \(error, privacy: .public)")
    }
  }

  /// Removes every entity as entities, which is what drops them from the
  /// semantic index Siri answers from; clearing the searchable items alone left
  /// Siri on the previous table after a selection change or an edit.
  @available(iOS 27.0, *)
  private static func removeAll(from index: CSSearchableIndex) async throws {
    try await index.deleteAppEntities(ofType: ClassEventEntity.self)
    try await index.deleteAppEntities(ofType: LectureEntity.self)
    try await index.deleteAllSearchableItems()
  }

  private static let logger = Logger(subsystem: "org.sparcs.soap", category: "TimetableIndex")

  /// Sign-out clears the tokens before the index, so a missing refresh token
  /// means there is no schedule to index. A locked keychain reads as signed out
  /// too, which skips the rebuild rather than risk indexing a stale account.
  private static var isSignedIn: Bool {
    ((try? tokenStorage.readRefreshToken()) ?? nil) != nil
  }

  private static let tokenStorage = TokenStorage()
}
