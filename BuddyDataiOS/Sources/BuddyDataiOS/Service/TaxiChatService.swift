//
//  TaxiChatService.swift
//  soap
//
//  Created by Soongyu Kwon on 19/07/2025.
//

import Foundation
import os
import SocketIO
import BuddyDomain
import BuddyDataCore

private let logger = Logger(subsystem: "org.sparcs.soap", category: "TaxiChatSocket")

// @unchecked Sendable: this type bridges SocketIO's callback-based API. Its
// scalar state is only mutated inside socket event handlers (delivered serially
// on the manager's handle queue), and its downstream streams are backed by
// `AsyncBroadcaster` actors, so it is safe to share across isolation domains.
public final class TaxiChatService: TaxiChatServiceProtocol, @unchecked Sendable {
  // MARK: - Broadcasters
  private let chatBroadcaster = AsyncBroadcaster<[TaxiChat]>()
  private let connectionBroadcaster = AsyncBroadcaster<Bool>(replaysLatest: true)
  private let roomUpdateBroadcaster = AsyncBroadcaster<String>()
  private let liveChatBroadcaster = AsyncBroadcaster<TaxiChat>()

  /// Minigame chats, which the app does not support. Their DTOs decode as text, so they are
  /// told apart by their raw type.
  private static let minigameChatTypes: Set<String> = ["wordChain", "racing", "raceLog"]

  public func chatStream() async -> AsyncStream<[TaxiChat]> {
    await chatBroadcaster.subscribe()
  }

  public func connectionStream() async -> AsyncStream<Bool> {
    await connectionBroadcaster.subscribe()
  }

  public func roomUpdateStream() async -> AsyncStream<String> {
    await roomUpdateBroadcaster.subscribe()
  }

  public func liveChatStream() async -> AsyncStream<TaxiChat> {
    await liveChatBroadcaster.subscribe()
  }

  private var chatsStorage: [TaxiChat] = []
  private var chats: [TaxiChat] {
    get { chatsStorage }
    set {
      chatsStorage = newValue
      let broadcaster = chatBroadcaster
      Task { await broadcaster.yield(newValue) }
    }
  }

  private var isConnectedStorage: Bool = false
  private var isConnected: Bool {
    get { isConnectedStorage }
    set {
      isConnectedStorage = newValue
      let broadcaster = connectionBroadcaster
      Task { await broadcaster.yield(newValue) }
    }
  }

  // MARK: - State
  private var hasAttemptedReconnect: Bool = false

  /// The access token the socket connected with, which Taxi knows it by.
  private var connectedToken: String?

  // MARK: - Dependency
  private let tokenStorage: TokenStorageProtocol
  private var manager: SocketManager
  private var socket: SocketIOClient

  // MARK: - Initialiser
  public init(tokenStorage: TokenStorageProtocol) {
    self.tokenStorage = tokenStorage

    let token = tokenStorage.getAccessToken()
    self.manager = Self.makeManager(token: token)
    self.socket = manager.defaultSocket
    self.connectedToken = token

    setupSocketEvents()

    socket.connect()
  }

  deinit {
    socket.disconnect()
  }

  public func disconnect() {
    // Not to be reconnected by the `.disconnect` handler, such as after signing out.
    hasAttemptedReconnect = true
    socket.disconnect()
  }

  public func reconnect() {
    // Mark this as an intentional reconnect so the `.disconnect` handler below
    // does not fire its own auto-reconnect for the disconnect we trigger here —
    // otherwise two competing connections race.
    hasAttemptedReconnect = true

    // A manager sends the headers it first connected with for as long as it lives, even when its
    // socket leaves and rejoins, so connecting with the current token takes a new one.
    socket.removeAllHandlers()
    socket.disconnect()
    manager.disconnect()

    let token = tokenStorage.getAccessToken()
    manager = Self.makeManager(token: token)
    socket = manager.defaultSocket
    connectedToken = token
    isConnected = false

    setupSocketEvents()
    socket.connect()
  }

  public func connectWithCurrentAccessToken() async {
    let isCurrent = await MainActor.run {
      // A socket on another token, or disconnected on purpose, such as after signing out.
      guard tokenStorage.getAccessToken() == connectedToken,
            socket.status == .connected || socket.status == .connecting else {
        reconnect()
        return false
      }
      return socket.status == .connected
    }
    guard !isCurrent else { return }

    // The socket joins the token's room as it connects, so a room's chats asked for before then
    // would go nowhere. Give up after a few seconds rather than never loading them.
    for _ in 0..<50 {
      if await MainActor.run(body: { socket.status == .connected }) { return }
      try? await Task.sleep(for: .milliseconds(100))
    }
    logger.error("Socket didn't connect with the current access token in time")
  }

  private static func makeManager(token: String?) -> SocketManager {
    SocketManager(
      socketURL: BackendURL.taxiSocketURL,
      config: [
        .log(false),
        .compress,
        .forceWebsockets(true),
        .extraHeaders([
          "Origin": "taxi.sparcs.org",
          "Authorization": "Bearer \(token ?? "")"
        ])
      ]
    )
  }

  private func setupSocketEvents() {
    socket.on(clientEvent: .connect) { _, _ in
      self.hasAttemptedReconnect = false
      self.isConnected = true
    }

    socket.on(clientEvent: .disconnect) { _, _ in
      self.isConnected = false

      if !self.hasAttemptedReconnect {
        self.hasAttemptedReconnect = true
        self.reconnect()
      }
    }

    socket.on(clientEvent: .error) { data, _ in
      logger.error("Socket error: \(String(describing: data), privacy: .public)")
    }

    // Retrieves recent chats
    socket.on("chat_init") { data, _ in
      guard let dataDict = data.first as? [String: Any],
            let chatArray = dataDict["chats"] as? [[String: Any]] else {
        return
      }

      self.chats = self.handleChats(chatArray)
    }

    // retrieves older chats
    socket.on("chat_push_front") { data, _ in
      guard let dataDict = data.first as? [String: Any],
            let chatArray = dataDict["chats"] as? [[String: Any]] else {
        return
      }

      let chats: [TaxiChat] = self.handleChats(chatArray)
      self.chats.insert(contentsOf: chats, at: 0)
    }

    socket.on("chat_push_back") { data, _ in
      guard let dataDict = data.first as? [String: Any],
            let chatArray = dataDict["chats"] as? [[String: Any]] else {
        return
      }

      let chats: [TaxiChat] = self.handleChats(chatArray)
      self.chats.append(contentsOf: chats)

      // Only a chat just sent carries its room ID; loading newer chats for a room does not.
      if dataDict["roomId"] != nil {
        let liveChats = self.handleChats(chatArray.filter {
          !Self.minigameChatTypes.contains($0["type"] as? String ?? "")
        })
        let broadcaster = self.liveChatBroadcaster
        Task {
          for chat in liveChats { await broadcaster.yield(chat) }
        }
      }
    }

    socket.on("chat_update") { data, _ in
      guard let dataDict = data.first as? [String: Any],
            let roomID = dataDict["roomId"] as? String else {
        return
      }

      let broadcaster = self.roomUpdateBroadcaster
      Task { await broadcaster.yield(roomID) }
    }
  }

  private func handleChats(_ data: [[String: Any]]) -> [TaxiChat] {
    do {
      let jsonData = try JSONSerialization.data(withJSONObject: data)
      let decoder = JSONDecoder()
      let chatDTOs: [TaxiChatDTO] = try decoder.decode([TaxiChatDTO].self, from: jsonData)

      let chats: [TaxiChat] = chatDTOs.compactMap { $0.toModel() }
      return chats
    } catch {
      return []
    }
  }
}
