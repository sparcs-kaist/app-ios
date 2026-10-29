//
//  TaxiQuickReplyUseCase.swift
//  BuddyDataiOS
//
//  Created by Soongyu Kwon on 28/10/2026.
//

import Foundation
import Synchronization
import BuddyDomain

public final class TaxiQuickReplyUseCase: TaxiQuickReplyUseCaseProtocol {
  /// A reply that took too long to send. It may still arrive.
  struct TimedOut: Error {}

  private let taxiChatRepository: TaxiChatRepositoryProtocol?
  private let sendTimeout: Duration
  private let readTimeout: Duration

  // iOS gives a notification's action about 30 seconds, so both fit well within it.
  public init(
    taxiChatRepository: TaxiChatRepositoryProtocol?,
    sendTimeout: Duration = .seconds(20),
    readTimeout: Duration = .seconds(5)
  ) {
    self.taxiChatRepository = taxiChatRepository
    self.sendTimeout = sendTimeout
    self.readTimeout = readTimeout
  }

  public func reply(_ text: String, roomID: String) async throws {
    guard let taxiChatRepository else { return }
    let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !text.isEmpty else { return }

    try await Self.giveUp(after: sendTimeout) {
      try await taxiChatRepository.sendChat(TaxiChatRequest(roomID: roomID, type: .text, content: text))
    }
    // Replying means you have read the room; failing to mark it only leaves its badge for now.
    try? await Self.giveUp(after: readTimeout) {
      try await taxiChatRepository.readChats(roomID: roomID)
    }
  }

  /// Runs `operation`, but stops waiting for it after `timeout`: network requests don't stop when
  /// cancelled, so this doesn't wait for them to.
  private static func giveUp(
    after timeout: Duration,
    _ operation: @escaping @Sendable () async throws -> Void
  ) async throws {
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
      let pending = Pending(continuation)
      let finish: @Sendable (Result<Void, Error>) -> Void = { pending.resume(with: $0) }
      let timer = Task {
        guard (try? await Task.sleep(for: timeout)) != nil else { return }
        finish(.failure(TimedOut()))
      }
      Task {
        do {
          try await operation()
          finish(.success(()))
        } catch {
          finish(.failure(error))
        }
        timer.cancel()
      }
    }
  }

  /// A continuation resumed once, by whichever of the work and the time running out finishes first.
  private final class Pending: Sendable {
    private let continuation: Mutex<CheckedContinuation<Void, Error>?>

    init(_ continuation: CheckedContinuation<Void, Error>) {
      self.continuation = Mutex(continuation)
    }

    func resume(with result: Result<Void, Error>) {
      continuation.withLock { continuation in
        continuation?.resume(with: result)
        continuation = nil
      }
    }
  }
}
