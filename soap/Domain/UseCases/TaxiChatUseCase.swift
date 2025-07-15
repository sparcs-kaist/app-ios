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
}

final class TaxiChatUseCase: TaxiChatUseCaseProtocol {
  // MARK: - Publishers
  private let chatsSubject = CurrentValueSubject<[String], Never>([])
  private let displayNewMessageSubject = CurrentValueSubject<Bool, Never>(false)

  var chatsPublisher: AnyPublisher<[String], Never> {
    chatsSubject.eraseToAnyPublisher()
  }

  var displayNewMessagePublisher: AnyPublisher<Bool, Never> {
    displayNewMessageSubject.eraseToAnyPublisher()
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
      socketURL: Constants.taxiBackendURL,
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

    socket.on(clientEvent: .connect) { data, _ in
      logger.debug("[TaxiChatUseCase] >>> Connected")
    }

    socket.onAny { event in
      print("📡 Socket Event - \(event.event):", event.items ?? [])
    }

    socket.connect()
  }

  func connect(to room: TaxiRoom) {
    self.room = room
    let roomId = room.id
    let repository = taxiChatRepository
    Task {
      do {
        try await repository.fetchChats(roomID: roomId)
      } catch {
        logger.error(error)
      }
    }
  }
}
