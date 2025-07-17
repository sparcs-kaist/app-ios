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

protocol TaxiChatUseCaseProtocol {
  func connect(to room: TaxiRoom)
  var chatsPublisher: AnyPublisher<[TaxiChat], Never> { get }
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

    //    socket.onAny { event in
    //      print("📡 Socket Event - \(event.event):", event.items ?? [])
    //    }
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

  func connect(to room: TaxiRoom) {
    logger.debug("Connecting to \(room.title)")
    self.room = room

    if socket.status == .connected {
      fetchInitialChats(for: room)
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
