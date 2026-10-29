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
  @ObservationIgnored private var taxiChatService: TaxiChatServiceProtocol?
  /// Whether the chat socket is connected for the account signed in now.
  @ObservationIgnored private var isSocketSignedIn = false

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
    // Follows signing in and out: the chat socket belongs to the account signed in.
    observationTasks.append(Task { [weak self, authUseCase] in
      guard let authUseCase else { return }
      for await isAuthenticated in authUseCase.isAuthenticatedPublisher.values {
        guard let self else { return }
        if isAuthenticated {
          await self.connectSocketIfNeeded()
        } else {
          self.signedOut()
        }
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

  /// Connects the chat socket for the account just signed in, once its access token is valid. The
  /// socket signs in once, with the token it connects with: made with an expired one, as at launch,
  /// it's turned away and the chat screen then waits for chats forever. Signing in and every token
  /// refresh publish again, so a failed refresh tries again on the next one.
  private func connectSocketIfNeeded() async {
    guard !isSocketSignedIn, (try? await authUseCase?.getValidAccessToken()) != nil else { return }
    isSocketSignedIn = true
    if let taxiChatService {
      await taxiChatService.connectWithCurrentAccessToken()
    } else if let service = makeTaxiChatService() {
      taxiChatService = service
      observeLiveChats(service)
    }
    await refresh()
  }

  /// Counts a chat from someone else in a room you are not looking at.
  private func observeLiveChats(_ taxiChatService: TaxiChatServiceProtocol) {
    observationTasks.append(Task { [weak self, userUseCase] in
      for await chat in await taxiChatService.liveChatStream() {
        guard let self else { return }
        let myID = await userUseCase?.taxiUser?.oid
        guard chat.isValid, chat.authorID == nil || chat.authorID != myID else { continue }
        guard chat.roomID != self.activeRoomID else { continue }
        self.counts[chat.roomID, default: 0] += 1
      }
    })
  }

  /// The next person to sign in mustn't get the previous account's chats, badges or notifications.
  private func signedOut() {
    isSocketSignedIn = false
    taxiChatService?.disconnect()
    activeRoomID = nil
    counts = [:]
    UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
      let identifiers = notifications
        .filter { ($0.request.content.userInfo["category"] as? String)?.hasPrefix("taxi_") == true }
        .map(\.request.identifier)
      guard !identifiers.isEmpty else { return }
      UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiers)
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
    UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
      let identifiers = notifications
        .filter { $0.request.content.threadIdentifier == roomID }
        .map(\.request.identifier)
      guard !identifiers.isEmpty else { return }
      // Looked up again rather than captured, as the center isn't Sendable.
      UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiers)
    }
  }
}
