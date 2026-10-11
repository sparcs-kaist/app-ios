//
//  SerialTaskQueue.swift
//  BuddyData
//

import Foundation

/// Runs async operations one at a time, in the order they were submitted.
///
/// Actor methods are re-entrant across `await`, so an actor alone doesn't stop a
/// second operation from starting while the first is suspended. Each operation
/// here waits for the previous one to finish first.
public actor SerialTaskQueue {
  private var tail: Task<Void, Never>?

  public init() {}

  public func run(_ operation: @escaping @Sendable () async -> Void) async {
    let previous = tail
    let task = Task {
      await previous?.value
      await operation()
    }
    tail = task
    await task.value
  }
}
