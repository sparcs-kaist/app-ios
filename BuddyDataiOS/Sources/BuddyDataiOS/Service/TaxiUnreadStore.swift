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

/// What the unread store changes outside the app: Taxi's delivered notifications and the app
/// icon's badge.
public protocol TaxiNotificationCleaning: Sendable {
  /// Removes the room's delivered notifications.
  func removeDelivered(roomID: String)
  /// Removes every delivered Taxi notification.
  func removeAllDelivered()
  func setBadgeCount(_ count: Int)
}

/// Taxi's notifications as the system delivered them.
public struct SystemTaxiNotifications: TaxiNotificationCleaning {
  public init() {}

  /// Taxi notifications are grouped by room, so the room's notifications are the ones whose thread
  /// is the room ID.
  public func removeDelivered(roomID: String) {
    removeDelivered { $0.request.content.threadIdentifier == roomID }
  }

  public func removeAllDelivered() {
    removeDelivered { ($0.request.content.userInfo["category"] as? String)?.hasPrefix("taxi_") == true }
  }

  public func setBadgeCount(_ count: Int) {
    UNUserNotificationCenter.current().setBadgeCount(count) { error in
      if let error {
        logger.error("Failed to set the app badge: \(error.localizedDescription, privacy: .public)")
      }
    }
  }

  private func removeDelivered(where matches: @escaping @Sendable (UNNotification) -> Bool) {
    UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
      let identifiers = notifications.filter(matches).map(\.request.identifier)
      guard !identifiers.isEmpty else { return }
      // Looked up again rather than captured, as the center isn't Sendable.
      UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiers)
    }
  }
}

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
  @ObservationIgnored private let notifications: TaxiNotificationCleaning
  /// Whether Buddy is in the foreground, as it changes, starting with now.
  @ObservationIgnored private let isInForeground: @MainActor () -> AsyncStream<Bool>

  // MARK: - State
  @ObservationIgnored private var observationTasks: [Task<Void, Never>] = []
  @ObservationIgnored private var taxiChatService: TaxiChatServiceProtocol?
  @ObservationIgnored private var liveChatsTask: Task<Void, Never>?
  @ObservationIgnored private var refreshTask: Task<Void, Never>?
  @ObservationIgnored private var isAuthenticated = false
  @ObservationIgnored private var isForeground = false
  /// Changes whenever you sign in or out, so counts fetched for a session that has ended are dropped.
  @ObservationIgnored private var session = 0
  /// Whether you're signed in with Buddy in the foreground, as of the last change to either.
  @ObservationIgnored private var isLive = false
  /// Whether the chat socket is connected for the account signed in now, or being connected.
  @ObservationIgnored private var isSocketSignedIn = false
  @ObservationIgnored private var isConnectingSocket = false
  /// Rooms that got chats on the socket while their counts were being fetched.
  @ObservationIgnored private var roomsChangedDuringRefresh: Set<String>?

  // Registered from the container, which is not on the main actor.
  public nonisolated init(
    taxiRoomRepository: TaxiRoomRepositoryProtocol?,
    makeTaxiChatService: @escaping @Sendable () -> TaxiChatServiceProtocol?,
    userUseCase: UserUseCaseProtocol?,
    authUseCase: AuthUseCaseProtocol?,
    notifications: TaxiNotificationCleaning = SystemTaxiNotifications(),
    isInForeground: @escaping @MainActor () -> AsyncStream<Bool> = TaxiUnreadStore.applicationIsInForeground
  ) {
    self.taxiRoomRepository = taxiRoomRepository
    self.makeTaxiChatService = makeTaxiChatService
    self.userUseCase = userUseCase
    self.authUseCase = authUseCase
    self.notifications = notifications
    self.isInForeground = isInForeground
    Task { @MainActor [weak self] in self?.observe() }
  }

  /// Replaces the counts with the server's. Only one runs at a time, and only while signed in: a
  /// request without an account is turned away and can end a sign-in under way.
  public func refresh() async {
    guard isAuthenticated else { return }
    if let refreshTask {
      return await refreshTask.value
    }
    let task = Task { await fetchCounts() }
    refreshTask = task
    await task.value
    if refreshTask == task { refreshTask = nil }
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
    notifications.removeDelivered(roomID: roomID)
  }

  // MARK: - Private

  private func fetchCounts() async {
    guard let taxiRoomRepository else { return }
    let fetchedSession = session
    roomsChangedDuringRefresh = []
    defer { if session == fetchedSession { roomsChangedDuringRefresh = nil } }
    // An expired access token isn't sent, and Taxi turns the request away as anonymous without it
    // being retried, so wait for the token to be refreshed, as it is at launch.
    _ = try? await authUseCase?.getValidAccessToken()
    do {
      let (onGoing, done) = try await taxiRoomRepository.fetchMyRooms()
      // Signed out, or in as someone else, while they were being fetched.
      guard session == fetchedSession else { return }
      let changedRooms = roomsChangedDuringRefresh ?? []
      var counts: [String: Int] = [:]
      for room in onGoing + done where room.id != activeRoomID {
        let fetched = room.unreadCount ?? 0
        // A chat that arrived meanwhile may not be in the server's count yet.
        counts[room.id] = changedRooms.contains(room.id) ? max(fetched, self.counts[room.id, default: 0]) : fetched
      }
      self.counts = counts
    } catch {
      logger.error("Failed to refresh unread chats: \(error.localizedDescription, privacy: .public)")
    }
  }

  // The counts are fetched, and chats listened to, while you're signed in with Buddy in the
  // foreground: as it opens, when you sign in, and whenever it comes back, as pushes received in
  // the background are only reflected in the server's counts. A reply from a notification, which
  // runs Buddy in the background, doesn't start the chat socket for nothing.
  private func observe() {
    observationTasks.append(Task { [weak self, authUseCase] in
      guard let authUseCase else { return }
      for await isAuthenticated in authUseCase.isAuthenticatedPublisher.values {
        guard let self else { return }
        self.authenticationChanged(to: isAuthenticated)
      }
    })

    let isInForeground = isInForeground()
    observationTasks.append(Task { [weak self] in
      for await isForeground in isInForeground {
        guard let self else { return }
        self.isForeground = isForeground
        self.update()
      }
    })
  }

  private func authenticationChanged(to isAuthenticated: Bool) {
    // The first state is handled even when signed out, to clear what a past session left.
    if isAuthenticated != self.isAuthenticated || session == 0 {
      self.isAuthenticated = isAuthenticated
      session += 1
      refreshTask?.cancel()
      refreshTask = nil
      if !isAuthenticated { signedOut() }
    }
    // Signing in and every token refresh publish again, so a socket that couldn't connect with an
    // expired token tries again on the next one.
    update()
  }

  private func update() {
    let isLive = isAuthenticated && isForeground
    defer { self.isLive = isLive }
    guard isLive else { return }
    Task { await connectSocketIfNeeded() }
    if !self.isLive {
      Task { await refresh() }
    }
  }

  /// Connects the chat socket for the account signed in, once its access token is valid. The
  /// socket signs in once, with the token it connects with: made with an expired one, as at launch,
  /// it's turned away and the chat screen then waits for chats forever.
  private func connectSocketIfNeeded() async {
    guard !isSocketSignedIn, !isConnectingSocket else { return }
    isConnectingSocket = true
    defer { isConnectingSocket = false }
    let connectingSession = session
    guard (try? await authUseCase?.getValidAccessToken()) != nil,
          session == connectingSession, isAuthenticated else { return }
    if let taxiChatService {
      await taxiChatService.connectWithCurrentAccessToken()
    } else if let service = makeTaxiChatService() {
      taxiChatService = service
    }
    guard let taxiChatService, session == connectingSession else { return }
    isSocketSignedIn = true
    if liveChatsTask == nil { observeLiveChats(taxiChatService) }
  }

  /// Counts a chat from someone else in a room you are not looking at.
  private func observeLiveChats(_ taxiChatService: TaxiChatServiceProtocol) {
    liveChatsTask = Task { [weak self, userUseCase] in
      for await chat in await taxiChatService.liveChatStream() {
        guard let self, !Task.isCancelled else { return }
        guard self.isAuthenticated else { continue }
        let myID = await userUseCase?.taxiUser?.oid
        guard chat.isValid, chat.authorID == nil || chat.authorID != myID else { continue }
        guard chat.roomID != self.activeRoomID else { continue }
        self.roomsChangedDuringRefresh?.insert(chat.roomID)
        self.counts[chat.roomID, default: 0] += 1
      }
    }
  }

  /// The next person to sign in mustn't get the previous account's chats, badges or notifications.
  private func signedOut() {
    isSocketSignedIn = false
    liveChatsTask?.cancel()
    liveChatsTask = nil
    taxiChatService?.disconnect()
    activeRoomID = nil
    counts = [:]
    notifications.removeAllDelivered()
  }

  /// The app icon's badge is Taxi's unread chats alone: no other notification sets it, and Taxi's
  /// pushes carry the same total from the server. Anything else that wants a badge must be added
  /// to this count here and on the server, or the two will keep replacing each other.
  private func updateAppBadge() {
    notifications.setBadgeCount(totalCount)
  }

  /// Whether the app is in the foreground, from now on.
  public static func applicationIsInForeground() -> AsyncStream<Bool> {
    AsyncStream { continuation in
      let center = NotificationCenter.default
      continuation.yield(UIApplication.shared.applicationState != .background)
      let observers = [
        center.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { _ in
          continuation.yield(true)
        },
        center.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { _ in
          continuation.yield(false)
        },
      ]
      nonisolated(unsafe) let tokens = observers
      continuation.onTermination = { _ in tokens.forEach(center.removeObserver) }
    }
  }
}
