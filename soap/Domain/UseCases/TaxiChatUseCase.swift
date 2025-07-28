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

final class TaxiChatUseCase: TaxiChatUseCaseProtocol {
  // MARK: - Publishers
  private var groupedChatsSubject = CurrentValueSubject<[TaxiChatGroup], Never>([])
  var groupedChatsPublisher: AnyPublisher<[TaxiChatGroup], Never> {
    groupedChatsSubject.eraseToAnyPublisher()
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

  // MARK: - Dependency
  private let taxiChatService: TaxiChatServiceProtocol
  private let userUseCase: UserUseCaseProtocol
  private let taxiChatRepository: TaxiChatRepositoryProtocol

  init(
    taxiChatService: TaxiChatServiceProtocol,
    userUseCase: UserUseCaseProtocol,
    taxiChatRepository: TaxiChatRepositoryProtocol,
    room: TaxiRoom
  ) {
    self.taxiChatService = taxiChatService
    self.userUseCase = userUseCase
    self.taxiChatRepository = taxiChatRepository
    self.room = room

    bind()
  }

  func fetchChats(before date: Date) async {
    do {
      try await taxiChatRepository.fetchChats(roomID: room.id, before: date)
    } catch {
      logger.error(error)
    }
  }

  func sendChat(_ content: String?, type: TaxiChat.ChatType) async {
    do {
      let request = TaxiChatRequest(roomID: room.id, type: type, content: content)
      try await taxiChatRepository.sendChat(request)
    } catch {
      logger.error(error)
    }
  }

  func sendImage(_ content: UIImage) async throws {
    guard let imageData = content.compressForUpload(maxSizeMB: 1.0, maxDimension: 1000) else {
      return
    }

    let presignedURL: TaxiChatPresignedURLDTO = try await taxiChatRepository.getPresignedURL(roomID: room.id)
    try await taxiChatRepository.uploadImage(presignedURL: presignedURL, imageData: imageData)
    try await taxiChatRepository.notifyImageUploadComplete(id: presignedURL.id)
  }

  private func bind() {
    // is socket(TaxiChatService) connected
    taxiChatService.isConnectedPublisher
      .sink { [weak self] isConnected in
        if !(self?.isSocketConnected ?? false) && isConnected && !(self?.hasInitialChatsBeenFetched ?? false) {
          self?.fetchInitialChats()
        }

        self?.isSocketConnected = isConnected
      }
      .store(in: &cancellables)

    // converts [TaxiChat] into [TaxiChatGroup]
    taxiChatService.chatsPublisher
      .sink { [weak self] chats in
        Task {
          guard let self = self else { return }

          let user: TaxiUser? = await self.userUseCase.taxiUser
          let groupedChats = self.groupChats(chats, currentUserID: user?.oid ?? "")
          self.groupedChats = groupedChats
        }
      }
      .store(in: &cancellables)
  }

  private func fetchInitialChats() {
    guard !hasInitialChatsBeenFetched else { return }
    
    hasInitialChatsBeenFetched = true
    Task {
      do {
        try await taxiChatRepository.fetchChats(roomID: room.id)
      } catch {
        logger.error(error)
      }
    }
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
