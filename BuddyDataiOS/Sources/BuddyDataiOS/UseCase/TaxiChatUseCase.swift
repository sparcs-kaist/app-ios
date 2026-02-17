//
//  TaxiChatUseCase.swift
//  soap
//
//  Created by Soongyu Kwon on 15/07/2025.
//

import Foundation
import UIKit
import Combine
import SocketIO
import BuddyDomain

public final class TaxiChatUseCase: TaxiChatUseCaseProtocol, @unchecked Sendable {
  // MARK: - Publishers
  private var chatsSubject = PassthroughSubject<[TaxiChat], Never>()
  public var chatsPublisher: AnyPublisher<[TaxiChat], Never> {
    chatsSubject.eraseToAnyPublisher()
  }

  private var roomUpdateSubject = PassthroughSubject<TaxiRoom, Never>()
  public var roomUpdatePublisher: AnyPublisher<TaxiRoom, Never> {
    roomUpdateSubject.eraseToAnyPublisher()
  }

  // MARK: - State
  private var room: TaxiRoom?
  private var isSocketConnected: Bool = false
  private var hasInitialChatsBeenFetched: Bool = false
  private var flatChats: [TaxiChat] = []

  private var cancellables = Set<AnyCancellable>()

  // MARK: - Computed Properties
  public var accountChats: [TaxiChat] = []

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

  public func fetchInitialChats() async {
    guard !hasInitialChatsBeenFetched, let room else { return }
    guard let taxiChatRepository else { return }

    hasInitialChatsBeenFetched = true

    bind()

    do {
      try await taxiChatRepository.fetchChats(roomID: room.id)
    } catch {
      print(error)
    }
  }

  public func fetchChats(before date: Date) async {
    guard let taxiChatRepository, let room else { return }

    do {
      try await taxiChatRepository.fetchChats(roomID: room.id, before: date)
    } catch {
      print(error)
    }
  }

  public func sendChat(_ content: String?, type: TaxiChat.ChatType) async {
    guard let taxiChatRepository, let room else { return }

    // Optimistic insert
    if let content, let userUseCase {
      let user: TaxiUser? = await userUseCase.taxiUser
      let optimisticChat = TaxiChat(
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
      flatChats.append(optimisticChat)
      chatsSubject.send(flatChats)
    }

    do {
      let request = TaxiChatRequest(roomID: room.id, type: type, content: content)
      try await taxiChatRepository.sendChat(request)
    } catch {
      print(error)
    }
  }

  public func sendImage(_ content: UIImage) async throws {
    guard let taxiChatRepository, let room else { return }

    guard let imageData = content.compressForUpload(maxSizeMB: 1.0, maxDimension: 1000) else {
      return
    }

    let presignedURL: TaxiChatPresignedURL = try await taxiChatRepository.getPresignedURL(roomID: room.id)
    try await taxiChatRepository.uploadImage(presignedURL: presignedURL, imageData: imageData)
    try await taxiChatRepository.notifyImageUploadComplete(id: presignedURL.id)
  }

  private func bind() {
    guard let taxiChatRepository, let taxiRoomRepository, let userUseCase, let taxiChatService, let room else {
      return
    }

    // is socket(TaxiChatService) connected
    taxiChatService.isConnectedPublisher
      .sink { [weak self] isConnected in
        self?.isSocketConnected = isConnected
      }
      .store(in: &cancellables)

    // converts [TaxiChat] into [TaxiChatGroup]
    taxiChatService.chatsPublisher
      .sink { [weak self, taxiChatRepository] chats in
        Task { [weak self, taxiChatRepository] in
          guard let self else { return }

          try? await taxiChatRepository.readChats(roomID: room.id)

          self.flatChats = chats
          self.chatsSubject.send(chats)

          self.accountChats = chats.filter { $0.type == .account }
        }
      }
      .store(in: &cancellables)

    // handles room updates from chat_update event
    taxiChatService.roomUpdatePublisher
      .sink { [weak self, taxiRoomRepository] roomID in
        Task { [weak self, taxiRoomRepository] in
          guard let self, roomID == room.id else { return }

          do {
            let updatedRoom: TaxiRoom = try await taxiRoomRepository.getRoom(id: roomID)
            self.room = updatedRoom
            self.roomUpdateSubject.send(updatedRoom)
          } catch {
            print("Failed to update room: \(error)")
          }
        }
      }
      .store(in: &cancellables)
  }
}
