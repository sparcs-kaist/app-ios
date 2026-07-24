//
//  TaxiChatUseCase.swift
//  soap
//
//  Created by Soongyu Kwon on 15/07/2025.
//

import Foundation
import Combine
import os
import SocketIO
import BuddyDomain

private let logger = Logger(subsystem: "org.sparcs.soap", category: "TaxiChat")

public actor TaxiChatUseCase: TaxiChatUseCaseProtocol {
  // MARK: - Broadcasters
  private let chatBroadcaster = AsyncBroadcaster<[TaxiChat]>(replaysLatest: true)
  private let roomUpdateBroadcaster = AsyncBroadcaster<TaxiRoom>()

  public func chatStream() async -> AsyncStream<[TaxiChat]> {
    await chatBroadcaster.subscribe()
  }

  public func roomUpdateStream() async -> AsyncStream<TaxiRoom> {
    await roomUpdateBroadcaster.subscribe()
  }

  // MARK: - State
  private var room: TaxiRoom?
  private var isSocketConnected: Bool = false
  private var hasInitialChatsBeenFetched: Bool = false
  private var flatChats: [TaxiChat] = []

  private var observationTasks: [Task<Void, Never>] = []

  // MARK: - Dependency
  private let taxiChatService: TaxiChatServiceProtocol?
  private let userUseCase: UserUseCaseProtocol?
  private let taxiChatRepository: TaxiChatRepositoryProtocol?
  private let taxiRoomRepository: TaxiRoomRepositoryProtocol?

  public init(
    taxiChatService: TaxiChatServiceProtocol?,
    userUseCase: UserUseCaseProtocol?,
    taxiChatRepository: TaxiChatRepositoryProtocol?,
    taxiRoomRepository: TaxiRoomRepositoryProtocol?
  ) {
    self.taxiChatService = taxiChatService
    self.userUseCase = userUseCase
    self.taxiChatRepository = taxiChatRepository
    self.taxiRoomRepository = taxiRoomRepository
  }

  public func setRoom(_ room: TaxiRoom) {
    self.room = room
  }

  public func reconnect() {
    taxiChatService?.reconnect()
  }

  public func fetchInitialChats() async {
    guard !hasInitialChatsBeenFetched, let room else { return }
    guard let taxiChatRepository else { return }

    hasInitialChatsBeenFetched = true

    await bind()

    do {
      try await taxiChatRepository.fetchChats(roomID: room.id)
    } catch {
      logger.error("Failed to fetch initial chats: \(error.localizedDescription, privacy: .public)")
    }
  }

  public func fetchChats(before date: Date) async {
    guard let taxiChatRepository, let room else { return }

    do {
      try await taxiChatRepository.fetchChats(roomID: room.id, before: date)
    } catch {
      logger.error("Failed to fetch chats before \(date, privacy: .public): \(error.localizedDescription, privacy: .public)")
    }
  }

  public func sendChat(_ content: String?, type: TaxiChat.ChatType) async throws {
    guard let taxiChatRepository, let room else { return }

    // Optimistic insert
    var optimisticChat: TaxiChat?
    if let content, let userUseCase {
      let user: TaxiUser? = await userUseCase.taxiUser
      let chat = TaxiChat(
        roomID: room.id,
        type: type,
        authorID: user?.oid,
        authorName: user?.nickname,
        authorProfileURL: user?.profileImageURL,
        authorIsWithdrew: false,
        content: content,
        time: Date(),
        isValid: true,
        inOutNames: nil
      )
      optimisticChat = chat
      flatChats.append(chat)
      await chatBroadcaster.yield(flatChats)
    }

    do {
      let request = TaxiChatRequest(roomID: room.id, type: type, content: content)
      try await taxiChatRepository.sendChat(request)
    } catch {
      // Roll back the optimistic insert so a failed message doesn't look sent.
      if let optimisticChat {
        flatChats.removeAll { $0.id == optimisticChat.id }
        await chatBroadcaster.yield(flatChats)
      }
      logger.error("Failed to send chat: \(error.localizedDescription, privacy: .public)")
      throw error
    }
  }

  public func sendImage(_ content: PlatformImage) async throws {
    guard let taxiChatRepository, let room else { return }

    guard let imageData = content.compressForUpload(maxSizeMB: 1.0, maxDimension: 1000) else {
      return
    }

    let presignedURL: TaxiChatPresignedURL = try await taxiChatRepository.getPresignedURL(roomID: room.id)
    try await taxiChatRepository.uploadImage(presignedURL: presignedURL, imageData: imageData)
    try await taxiChatRepository.notifyImageUploadComplete(id: presignedURL.id)
  }

  private func bind() async {
    guard let taxiChatService, let room else {
      return
    }

    let roomID = room.id
    let connectionStream = await taxiChatService.connectionStream()
    let serviceChatStream = await taxiChatService.chatStream()
    let serviceRoomUpdateStream = await taxiChatService.roomUpdateStream()

    // is socket(TaxiChatService) connected
    observationTasks.append(Task { [weak self] in
      for await isConnected in connectionStream {
        guard let self else { return }
        await self.setSocketConnected(isConnected)
      }
    })

    // forwards chats downstream, marking them read
    observationTasks.append(Task { [weak self] in
      for await chats in serviceChatStream {
        guard let self else { return }
        await self.handleServiceChats(chats, roomID: roomID)
      }
    })

    // handles room updates from chat_update event
    observationTasks.append(Task { [weak self] in
      for await updatedRoomID in serviceRoomUpdateStream {
        guard let self else { return }
        guard updatedRoomID == roomID else { continue }
        await self.handleRoomUpdate(roomID: updatedRoomID)
      }
    })
  }

  private func setSocketConnected(_ isConnected: Bool) {
    isSocketConnected = isConnected
  }

  private func handleServiceChats(_ chats: [TaxiChat], roomID: String) async {
    try? await taxiChatRepository?.readChats(roomID: roomID)
    flatChats = chats
    await chatBroadcaster.yield(chats)
  }

  private func handleRoomUpdate(roomID: String) async {
    guard let taxiRoomRepository else { return }
    do {
      let updatedRoom: TaxiRoom = try await taxiRoomRepository.getRoom(id: roomID)
      room = updatedRoom
      await roomUpdateBroadcaster.yield(updatedRoom)
    } catch {
      logger.error("Failed to update room: \(error.localizedDescription, privacy: .public)")
    }
  }

  deinit {
    observationTasks.forEach { $0.cancel() }
  }
}
