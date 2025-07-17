//
//  TaxiChatUseCase.swift
//  soap
//
//  Created by Soongyu Kwon on 15/07/2025.
//

import Foundation
import Combine
import SocketIO

import Playgrounds

@MainActor
protocol TaxiChatUseCaseProtocol {
  var chatsPublisher: AnyPublisher<[TaxiChat], Never> { get }

  func connect(to room: TaxiRoom)
  func fetchChats(before date: Date) async
}

final class TaxiChatUseCase: TaxiChatUseCaseProtocol {
  // MARK: - Publishers
  private let chatsSubject = CurrentValueSubject<[TaxiChat], Never>([])

  var chatsPublisher: AnyPublisher<[TaxiChat], Never> {
    chatsSubject.eraseToAnyPublisher()
  }

  // MARK: - State
  private var room: TaxiRoom?
  private var isSendingMessage = false
  private var manager: SocketManager
  private var socket: SocketIOClient

  // MARK: - Dependency
  private let tokenStorage: TokenStorageProtocol
  private let taxiChatRepository: TaxiChatRepositoryProtocol

  init(tokenStorage: TokenStorageProtocol, taxiChatRepository: TaxiChatRepositoryProtocol) {
    self.tokenStorage = tokenStorage
    self.taxiChatRepository = taxiChatRepository

    let manager = SocketManager(
      socketURL: Constants.taxiSocketURL,
      config: [
        .log(true),
        .compress,
        .forceWebsockets(true),
        .extraHeaders([
          "Origin": "sparcsapp",
          "Authorization": "Bearer \(self.tokenStorage.getAccessToken() ?? "")"
        ])
      ]
    )

    self.manager = manager
    self.socket = self.manager.defaultSocket

    setupSocketEvents()

    socket.connect()
  }

  func setupSocketEvents() {
    socket.on(clientEvent: .connect) { data, _ in
      logger.debug("[TaxiChatUseCase] >>> Connected")

      if let room = self.room {
        self.fetchInitialChats(for: room)
      }
    }

    socket.on("chat_init") { data, _ in
      logger.debug("[TaxiChatUseCase] <<< chat_init")
      guard let dataDict = data.first as? [String: Any],
            let chatArray = dataDict["chats"] as? [[String: Any]] else {
        return
      }

      self.handleChats(chatArray)
    }

    socket.on("chat_push_front") { data, _ in
      logger.debug("[TaxiChatUseCase] <<< chat_push_front")
      guard let dataDict = data.first as? [String: Any],
            let chatArray = dataDict["chats"] as? [[String: Any]] else {
        return
      }

      self.handlePushFront(chatArray)
    }

    socket.onAny { event in
      print("📡 Socket Event - \(event.event):", event.items ?? [])
    }
  }

  private func handleChats(_ data: [[String: Any]]) {
    do {
      let jsonData = try JSONSerialization.data(withJSONObject: data)
      let decoder = JSONDecoder()
      let chatDTOs = try decoder.decode([TaxiChatDTO].self, from: jsonData)

      let chats = chatDTOs.compactMap { $0.toModel() }
      chatsSubject.send(chats)
    } catch {
      logger.error("Failed to decode chats: \(error.localizedDescription)")
    }
  }

  private func handlePushFront(_ data: [[String: Any]]) {
    do {
      let jsonData = try JSONSerialization.data(withJSONObject: data)
      let decoder = JSONDecoder()
      let chatDTOs = try decoder.decode([TaxiChatDTO].self, from: jsonData)

      let newChats = chatDTOs.compactMap { $0.toModel() }

      // Prepend newChats to existing chats
      let updatedChats = newChats + chatsSubject.value
      chatsSubject.send(updatedChats)
    } catch {
      logger.error("Failed to decode chats: \(error.localizedDescription)")
    }
  }

  func connect(to room: TaxiRoom) {
    logger.debug("Connecting to \(room.title)")
    self.room = room

    if socket.status == .connected {
      fetchInitialChats(for: room)
    }
  }

  func fetchChats(before date: Date) async {
    logger.debug("Fetching chats before \(date.formattedString)")
    guard let roomID = self.room?.id else {
      logger.error("lost room id")
      return
    }

    if socket.status == .connected {
      do {
        try await taxiChatRepository.fetchChats(roomID: roomID, before: date)
      } catch {
        logger.error(error)
      }
    }
  }

  private func fetchInitialChats(for room: TaxiRoom) {
    let roomID = room.id
    let repository = taxiChatRepository
    Task {
      do {
        try await repository.fetchChats(roomID: roomID)
      } catch {
        logger.error(error)
      }
    }
  }
}
