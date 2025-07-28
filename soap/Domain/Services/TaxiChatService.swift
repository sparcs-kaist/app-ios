//
//  TaxiChatService.swift
//  soap
//
//  Created by Soongyu Kwon on 19/07/2025.
//

import Foundation
import Combine
import SocketIO

final class TaxiChatService: TaxiChatServiceProtocol {
  // MARK: - Publisher
  private var chatsSubject = CurrentValueSubject<[TaxiChat], Never>([])
  var chatsPublisher: AnyPublisher<[TaxiChat], Never> {
    chatsSubject.eraseToAnyPublisher()
  }

  private var isConnectedSubject = CurrentValueSubject<Bool, Never>(false)
  var isConnectedPublisher: AnyPublisher<Bool, Never> {
    isConnectedSubject.eraseToAnyPublisher()
  }

  private var chats: [TaxiChat] {
    get { chatsSubject.value }
    set { chatsSubject.send(newValue) }
  }

  private var isConnected: Bool {
    get { isConnectedSubject.value }
    set { isConnectedSubject.send(newValue) }
  }

  // MARK: - Dependency
  private let tokenStorage: TokenStorageProtocol
  private let manager: SocketManager
  private let socket: SocketIOClient

  // MARK: - Initialiser
  init(tokenStorage: TokenStorageProtocol) {
    self.tokenStorage = tokenStorage

    self.manager = SocketManager(
      socketURL: Constants.taxiSocketURL,
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

  private func setupSocketEvents() {
    socket.on(clientEvent: .connect) { _, _ in
      logger.debug("[TaxiChatService] >>> Connected")
      self.isConnected = true
    }

    // Retrieves recent chats
    socket.on("chat_init") { data, _ in
      logger.debug("[TaxiChatService] <<< chat_init")
      guard let dataDict = data.first as? [String: Any],
            let chatArray = dataDict["chats"] as? [[String: Any]] else {
        return
      }

      self.chats = self.handleChats(chatArray)
    }

    // retrieves older chats
    socket.on("chat_push_front") { data, _ in
      logger.debug("[TaxiChatService] <<< chat_push_front")
      guard let dataDict = data.first as? [String: Any],
            let chatArray = dataDict["chats"] as? [[String: Any]] else {
        return
      }
      
      let chats: [TaxiChat] = self.handleChats(chatArray)
      self.chats.insert(contentsOf: chats, at: 0)
    }

    socket.on("chat_push_back") { data, _ in
      logger.debug("[TaxiChatService] <<< chat_push_back")
      guard let dataDict = data.first as? [String: Any],
            let chatArray = dataDict["chats"] as? [[String: Any]] else {
        return
      }

      let chats: [TaxiChat] = self.handleChats(chatArray)
      self.chats.append(contentsOf: chats)
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
