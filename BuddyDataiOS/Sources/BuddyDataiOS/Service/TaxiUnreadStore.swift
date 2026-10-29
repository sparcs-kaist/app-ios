//
//  TaxiUnreadStore.swift
//  BuddyDataiOS
//
//  Created by Soongyu Kwon on 28/10/2026.
//

import Combine
import Foundation
import Observation
import UIKit
import UserNotifications
import os
import BuddyDomain

private let logger = Logger(subsystem: "org.sparcs.soap", category: "TaxiUnread")

@MainActor
@Observable
public final class TaxiUnreadStore: TaxiUnreadStoreProtocol {
  public private(set) var counts: [String: Int] = [:] {
    didSet { updateAppBadge() }
  }
  public private(set) var activeRoomID: String?

  public var totalCount: Int {
    counts.values.reduce(0, +)
  }

  // MARK: - Dependency
  @ObservationIgnored private let taxiRoomRepository: TaxiRoomRepositoryProtocol?
  // The chat service connects its socket as soon as it's made, so it's made only when needed.
  @ObservationIgnored private let makeTaxiChatService: @Sendable () -> TaxiChatServiceProtocol?
  @ObservationIgnored private let userUseCase: UserUseCaseProtocol?
  @ObservationIgnored private let authUseCase: AuthUseCaseProtocol?

  @ObservationIgnored private var observationTasks: [Task<Void, Never>] = []

  // Registered from the container, which is not on the main actor.
  public nonisolated init(
    taxiRoomRepository: TaxiRoomRepositoryProtocol?,
    makeTaxiChatService: @escaping @Sendable () -> TaxiChatServiceProtocol?,
    userUseCase: UserUseCaseProtocol?,
    authUseCase: AuthUseCaseProtocol?
  ) {
    self.taxiRoomRepository = taxiRoomRepository
    self.makeTaxiChatService = makeTaxiChatService
    self.userUseCase = userUseCase
    self.authUseCase = authUseCase
    Task { @MainActor [weak self] in self?.observe() }
  }

  public func refresh() async {
    guard let taxiRoomRepository else { return }
    // An expired access token isn't sent, and Taxi turns the request away as anonymous without it
    // being retried, so wait for the token to be refreshed, as it is at launch.
    _ = try? await authUseCase?.getValidAccessToken()
    do {
      let (onGoing, done) = try await taxiRoomRepository.fetchMyRooms()
      var counts: [String: Int] = [:]
      for room in onGoing + done where room.id != activeRoomID {
        counts[room.id] = room.unreadCount ?? 0
      }
      self.counts = counts
    } catch {
      logger.error("Failed to refresh unread chats: \(error.localizedDescription, privacy: .public)")
    }
  }

  public func enterRoom(_ roomID: String) {
    activeRoomID = roomID
    markRead(roomID)
  }

  public func leaveRoom(_ roomID: String) {
    guard activeRoomID == roomID else { return }
    activeRoomID = nil
  }

  public func markRead(_ roomID: String) {
    if counts[roomID, default: 0] != 0 {
      counts[roomID] = 0
    }
    removeDeliveredNotifications(roomID: roomID)
  }

  // MARK: - Private

  private func observe() {
    // Counts a chat from someone else in a room you are not looking at.
    observationTasks.append(Task { [weak self, makeTaxiChatService, userUseCase, authUseCase] in
      // The socket signs in once, with the access token it connects with. Made with an expired
      // one, as at launch, it's turned away and the chat screen then waits for chats forever.
      await Self.waitForValidAccessToken(authUseCase)
      guard let taxiChatService = makeTaxiChatService() else { return }
      for await chat in await taxiChatService.liveChatStream() {
        guard let self else { return }
        let myID = await userUseCase?.taxiUser?.oid
        guard chat.isValid, chat.authorID == nil || chat.authorID != myID else { continue }
        guard chat.roomID != self.activeRoomID else { continue }
        self.counts[chat.roomID, default: 0] += 1
      }
    })

    // Pushes received while the app was in the background are only reflected in the server's
    // counts, so fetch them again whenever the app comes back.
    observationTasks.append(Task { [weak self] in
      let becameActive = NotificationCenter.default.notifications(
        named: UIApplication.didBecomeActiveNotification
      )
      for await _ in becameActive {
        guard let self else { return }
        await self.refresh()
      }
    })
  }

  /// Returns once you're signed in with a valid access token, refreshing it if needed. Signing in
  /// and every token refresh publish again, so a failed refresh waits for the next one.
  private static func waitForValidAccessToken(_ authUseCase: AuthUseCaseProtocol?) async {
    guard let authUseCase else { return }
    for await isAuthenticated in authUseCase.isAuthenticatedPublisher.values where isAuthenticated {
      if (try? await authUseCase.getValidAccessToken()) != nil { return }
    }
  }

  private func updateAppBadge() {
    let total = totalCount
    UNUserNotificationCenter.current().setBadgeCount(total) { error in
      if let error {
        logger.error("Failed to set the app badge: \(error.localizedDescription, privacy: .public)")
      }
    }
  }

  /// Taxi notifications are grouped by room, so the room's notifications are the ones whose thread
  /// is the room ID.
  private func removeDeliveredNotifications(roomID: String) {
    let center = UNUserNotificationCenter.current()
    center.getDeliveredNotifications { notifications in
      let identifiers = notifications
        .filter { $0.request.content.threadIdentifier == roomID }
        .map(\.request.identifier)
      guard !identifiers.isEmpty else { return }
      center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }
  }
}
