//
//  AsyncBroadcaster.swift
//  BuddyDataiOS
//
//  A multicast async broadcaster: each `subscribe()` returns a fresh
//  `AsyncStream`, and every `yield(_:)` fans the value out to all current
//  subscribers. This replaces multicast Combine subjects (PassthroughSubject /
//  CurrentValueSubject) for long-lived, shared (singleton) producers where a
//  single-consumer `AsyncStream` would be insufficient.
//

import Foundation

public actor AsyncBroadcaster<Element: Sendable> {
  private var continuations: [UUID: AsyncStream<Element>.Continuation] = [:]
  private var latest: Element?
  private let replaysLatest: Bool

  /// - Parameter replaysLatest: when `true`, a new subscriber immediately
  ///   receives the most recently yielded value (mirrors `CurrentValueSubject`).
  public init(replaysLatest: Bool = false) {
    self.replaysLatest = replaysLatest
  }

  /// Registers a new subscriber and returns its stream. The subscription is
  /// removed automatically when the stream's consumer stops iterating.
  public func subscribe() -> AsyncStream<Element> {
    let id = UUID()
    let (stream, continuation) = AsyncStream<Element>.makeStream()
    continuations[id] = continuation

    if replaysLatest, let latest {
      continuation.yield(latest)
    }

    continuation.onTermination = { [weak self] _ in
      Task { await self?.remove(id) }
    }

    return stream
  }

  /// Fans `element` out to every current subscriber.
  public func yield(_ element: Element) {
    latest = element
    for continuation in continuations.values {
      continuation.yield(element)
    }
  }

  /// Finishes all subscriber streams and drops them.
  public func finish() {
    for continuation in continuations.values {
      continuation.finish()
    }
    continuations.removeAll()
  }

  private func remove(_ id: UUID) {
    continuations[id] = nil
  }
}
