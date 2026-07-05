//
//  TaxiChatService.swift
//  soap
//
//  Created by Soongyu Kwon on 19/07/2025.
//

import Foundation
import SocketIO
import BuddyDomain
import BuddyDataCore

// @unchecked Sendable: this type bridges SocketIO's callback-based API. Its
// scalar state is only mutated inside socket event handlers (delivered serially
// on the manager's handle queue), and its downstream streams are backed by
// `AsyncBroadcaster` actors, so it is safe to share across isolation domains.
public final class TaxiChatService: TaxiChatServiceProtocol, @unchecked Sendable {
  // MARK: - Broadcasters
  private let chatBroadcaster = AsyncBroadcaster<[TaxiChat]>()
  private let connectionBroadcaster = AsyncBroadcaster<Bool>(replaysLatest: true)
  private let roomUpdateBroadcaster = AsyncBroadcaster<String>()

  public func chatStream() async -> AsyncStream<[TaxiChat]> {
    await chatBroadcaster.subscribe()
  }

  public func connectionStream() async -> AsyncStream<Bool> {
    await connectionBroadcaster.subscribe()
  }

  public func roomUpdateStream() async -> AsyncStream<String> {
    await roomUpdateBroadcaster.subscribe()
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

  // MARK: - Dependency
  private let tokenStorage: TokenStorageProtocol
  private let manager: SocketManager
  private let socket: SocketIOClient

  // MARK: - Initialiser
  public init(tokenStorage: TokenStorageProtocol) {
    self.tokenStorage = tokenStorage

    self.manager = SocketManager(
      socketURL: BackendURL.taxiSocketURL,
      config: [
        .log(false),
        .compress,
        .forceWebsockets(true),
        .extraHeaders([
          "Origin": "taxi.sparcs.org",
          "Authorization": "Bearer \(self.tokenStorage.getAccessToken() ?? "")"
        ])
      ]
    )

    self.socket = self.manager.defaultSocket

    setupSocketEvents()

    socket.connect()
  }

  deinit {
    socket.disconnect()
  }

  public func disconnect() {
    socket.disconnect()
  }

  public func reconnect() {
    socket.disconnect()
    manager.config = [
      .log(false),
      .compress,
      .forceWebsockets(true),
      .extraHeaders([
        "Origin": "taxi.sparcs.org",
        "Authorization": "Bearer \(tokenStorage.getAccessToken() ?? "")"
      ])
    ]
    socket.connect()
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
      print("[TaxiChatService] Socket error: \(data)")
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
    }

    socket.on("chat_update") { data, _ in
      guard let dataDict = data.first as? [String: Any],
            let roomID = dataDict["roomId"] as? String else {
        return
      }

      let broadcaster = self.roomUpdateBroadcaster
      Task { await broadcaster.yield(roomID) }
    }

//    socket.onAny { event in
//      print("📡 Socket Event - \(event.event):", event.items ?? [])
//    }
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
