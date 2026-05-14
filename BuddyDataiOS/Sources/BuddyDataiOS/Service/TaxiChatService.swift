//
//  TaxiChatService.swift
//  soap
//
//  Created by Soongyu Kwon on 19/07/2025.
//

import Foundation
import Combine
import SocketIO
import BuddyDomain
import BuddyDataCore

public final class TaxiChatService: TaxiChatServiceProtocol {
  // MARK: - Publisher
  private var chatsSubject = PassthroughSubject<[TaxiChat], Never>()
  public var chatsPublisher: AnyPublisher<[TaxiChat], Never> {
    chatsSubject.eraseToAnyPublisher()
  }

  private var isConnectedSubject = CurrentValueSubject<Bool, Never>(false)
  public var isConnectedPublisher: AnyPublisher<Bool, Never> {
    isConnectedSubject.eraseToAnyPublisher()
  }

  private var roomUpdateSubject = PassthroughSubject<String, Never>()
  public var roomUpdatePublisher: AnyPublisher<String, Never> {
    roomUpdateSubject.eraseToAnyPublisher()
  }

  private var chatsStorage: [TaxiChat] = []
  private var chats: [TaxiChat] {
    get { chatsStorage }
    set {
      chatsStorage = newValue
      chatsSubject.send(newValue)
    }
  }

  private var isConnected: Bool {
    get { isConnectedSubject.value }
    set { isConnectedSubject.send(newValue) }
  }

  // MARK: - State
  private var hasAttemptedReconnect: Bool = false
  private var shouldReconnectAfterDisconnect: Bool = true
  
  // prevent connection loss on token refresh
  private var connectedToken: String?
  private var connectingToken: String?

  // MARK: - Dependency
  private let tokenStorage: TokenStorageProtocol
  private let manager: SocketManager
  private let socket: SocketIOClient

  // MARK: - Initialiser
  public init(tokenStorage: TokenStorageProtocol) {
    self.tokenStorage = tokenStorage
    let accessToken = self.tokenStorage.getAccessToken()

    self.manager = SocketManager(
      socketURL: BackendURL.taxiSocketURL,
      config: Self.socketConfig(accessToken: accessToken)
    )

    self.socket = self.manager.defaultSocket
    self.connectingToken = accessToken

    setupSocketEvents()

    socket.connect()
  }

  deinit {
    socket.disconnect()
  }

  public func disconnect() {
    shouldReconnectAfterDisconnect = false
    connectedToken = nil
    connectingToken = nil
    isConnected = false
    socket.disconnect()
  }

  public func reconnect() {
    let accessToken = tokenStorage.getAccessToken()
    guard accessToken?.isEmpty == false else {
      disconnect()
      return
    }

    connectedToken = nil
    connectingToken = accessToken
    isConnected = false
    shouldReconnectAfterDisconnect = false
    socket.disconnect()
    manager.config = Self.socketConfig(accessToken: accessToken)
    socket.connect()
  }

  public func ensureConnectedWithLatestToken() async -> Bool {
    guard let accessToken = tokenStorage.getAccessToken(), !accessToken.isEmpty else {
      disconnect()
      return false
    }

    if isConnected, connectedToken == accessToken {
      return true
    }

    reconnect()

    return await waitUntilConnected(with: accessToken)
  }

  private func setupSocketEvents() {
    socket.on(clientEvent: .connect) { _, _ in
      self.hasAttemptedReconnect = false
      self.shouldReconnectAfterDisconnect = true
      self.connectedToken = self.connectingToken
      self.isConnected = true
    }

    socket.on(clientEvent: .disconnect) { _, _ in
      self.isConnected = false
      self.connectedToken = nil

      guard self.shouldReconnectAfterDisconnect else {
        self.shouldReconnectAfterDisconnect = true
        return
      }

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

      self.roomUpdateSubject.send(roomID)
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

  private func waitUntilConnected(with accessToken: String, timeoutSeconds: UInt64 = 5) async -> Bool {
    let deadline = Date().addingTimeInterval(TimeInterval(timeoutSeconds))

    while Date() < deadline {
      if isConnected, connectedToken == accessToken {
        return true
      }

      try? await Task.sleep(nanoseconds: 100_000_000)
    }

    return isConnected && connectedToken == accessToken
  }

  private static func socketConfig(accessToken: String?) -> SocketIOClientConfiguration {
    [
      .log(false),
      .compress,
      .forceWebsockets(true),
      .extraHeaders([
        "Origin": "taxi.sparcs.org",
        "Authorization": "Bearer \(accessToken ?? "")"
      ])
    ]
  }
}
