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
  private var groupedChatsSubject = CurrentValueSubject<[TaxiChatGroup], Never>([])
  public var groupedChatsPublisher: AnyPublisher<[TaxiChatGroup], Never> {
    groupedChatsSubject.eraseToAnyPublisher()
  }

  private var roomUpdateSubject = PassthroughSubject<TaxiRoom, Never>()
  public var roomUpdatePublisher: AnyPublisher<TaxiRoom, Never> {
    roomUpdateSubject.eraseToAnyPublisher()
  }

  private var groupedChats: [TaxiChatGroup] {
    get { groupedChatsSubject.value }
    set { groupedChatsSubject.send(newValue) }
  }

  // MARK: - State
  private var room: TaxiRoom
  private var isSocketConnected: Bool = false
  private var hasInitialChatsBeenFetched: Bool = false

  private var cancellables = Set<AnyCancellable>()

  // MARK: - Computed Properties
  public var accountChats: [TaxiChat] = []

  // MARK: - Dependency
  private let taxiChatService: TaxiChatServiceProtocol
  private let userUseCase: UserUseCaseProtocol?
  private let taxiChatRepository: TaxiChatRepositoryProtocol?
  private let taxiRoomRepository: TaxiRoomRepositoryProtocol?

  public init(
    taxiChatService: TaxiChatServiceProtocol,
    userUseCase: UserUseCaseProtocol?,
    taxiChatRepository: TaxiChatRepositoryProtocol?,
    taxiRoomRepository: TaxiRoomRepositoryProtocol?,
    room: TaxiRoom
  ) {
    self.taxiChatService = taxiChatService
    self.userUseCase = userUseCase
    self.taxiChatRepository = taxiChatRepository
    self.taxiRoomRepository = taxiRoomRepository
    self.room = room
  }

  public func fetchInitialChats() async {
    guard !hasInitialChatsBeenFetched else { return }
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
    guard let taxiChatRepository else { return }

    do {
      try await taxiChatRepository.fetchChats(roomID: room.id, before: date)
    } catch {
      print(error)
    }
  }

  public func sendChat(_ content: String?, type: TaxiChat.ChatType) async {
    guard let taxiChatRepository else { return }

    do {
      let request = TaxiChatRequest(roomID: room.id, type: type, content: content)
      try await taxiChatRepository.sendChat(request)
    } catch {
      print(error)
    }
  }

  public func sendImage(_ content: UIImage) async throws {
    guard let taxiChatRepository else { return }

    guard let imageData = content.compressForUpload(maxSizeMB: 1.0, maxDimension: 1000) else {
      return
    }

    let presignedURL: TaxiChatPresignedURL = try await taxiChatRepository.getPresignedURL(roomID: room.id)
    try await taxiChatRepository.uploadImage(presignedURL: presignedURL, imageData: imageData)
    try await taxiChatRepository.notifyImageUploadComplete(id: presignedURL.id)
  }

  private func bind() {
    guard let taxiChatRepository, let taxiRoomRepository, let userUseCase else { return }

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

          try? await taxiChatRepository.readChats(roomID: self.room.id)

          let user: TaxiUser? = await userUseCase.taxiUser
          let groupedChats = self.groupChats(chats, currentUserID: user?.oid ?? "")

          self.groupedChats = groupedChats
          self.accountChats = chats.filter { $0.type == .account }
        }
      }
      .store(in: &cancellables)

    // handles room updates from chat_update event
    taxiChatService.roomUpdatePublisher
      .sink { [weak self, taxiRoomRepository] roomID in
        Task { [weak self, taxiRoomRepository] in
          guard let self, roomID == self.room.id else { return }

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

  private func groupChats(_ chats: [TaxiChat], currentUserID: String) -> [TaxiChatGroup] {
    guard !chats.isEmpty else { return [] }

    var result: [TaxiChatGroup] = []
    var currentGroup: [TaxiChat] = []

    func flushGroup() {
      if !currentGroup.isEmpty {
        let time: Date = currentGroup.first?.time ?? Date()
        let isMe: Bool = currentGroup.first?.authorID == currentUserID
        let group = TaxiChatGroup(
          id: time.toISO8601,
          chats: currentGroup,
          lastChatID: currentGroup.last?.id,
          authorID: currentGroup.first?.authorID,
          authorName: currentGroup.first?.authorName,
          authorProfileURL: currentGroup.first?.authorProfileURL,
          authorIsWithdrew: currentGroup.first?.authorIsWithdrew,
          time: time,
          isMe: isMe,
          isGeneral: false
        )
        result.append(group)
        currentGroup = []
      }
    }

    let calendar = Calendar.current

    for chat in chats {
      if chat.type == .entrance || chat.type == .exit {
        flushGroup()
        let group = TaxiChatGroup(
          id: chat.time.toISO8601,
          chats: [chat],
          lastChatID: nil,
          authorID: chat.authorID,
          authorName: chat.authorName,
          authorProfileURL: chat.authorProfileURL,
          authorIsWithdrew: chat.authorIsWithdrew,
          time: chat.time,
          isMe: chat.authorID == currentUserID,
          isGeneral: true
        )
        result.append(group)
        continue
      }

      if currentGroup.isEmpty {
        currentGroup.append(chat)
        continue
      }

      let lastChat = currentGroup.last!
      let isSameAuthor = chat.authorID == lastChat.authorID
      let isSameMinute = calendar.isDate(chat.time, equalTo: lastChat.time, toGranularity: .minute)

      if isSameAuthor && isSameMinute {
        currentGroup.append(chat)
      } else {
        flushGroup()
        currentGroup = [chat]
      }
    }

    flushGroup()
    return result
  }
}
