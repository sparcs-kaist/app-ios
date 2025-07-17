//
//  TaxiChatViewModel.swift
//  soap
//
//  Created by Soongyu Kwon on 17/07/2025.
//

import SwiftUI
import Observation
import Factory
import Combine

struct TaxiChatGroup: Equatable {
  let chatGroup: [TaxiChat]
  let isMe: Bool
}

@MainActor
@Observable
class TaxiChatViewModel {
  // MARK: - Properties
  var chats: [TaxiChat] = []
  var groupedChats: [TaxiChatGroup] = []
  private var cancellables = Set<AnyCancellable>()
  private var isFetching: Bool = false

  // MARK: - Dependencies
  @ObservationIgnored @Injected(\.taxiChatUseCase) private var taxiChatUseCase: TaxiChatUseCaseProtocol
  @ObservationIgnored @Injected(\.userUseCase) private var userUseCase: UserUseCaseProtocol

  var nickname: String? {
    userUseCase.taxiUser?.nickname
  }

  func connect(to room: TaxiRoom) {
    taxiChatUseCase.chatsPublisher
      .receive(on: DispatchQueue.main)
      .print()
      .sink { [weak self] chats in
        guard let self = self else { return }
        self.chats = chats
        self.groupedChats = self
          .groupChats(chats, currentUserID: self.userUseCase.taxiUser?.oid ?? "")

        logger.debug("grouped: \(groupedChats)")
      }
      .store(in: &cancellables)
    taxiChatUseCase.connect(to: room)
  }

  func fetchChats(before date: Date) async {
    if isFetching { return }
    isFetching = true
    defer { isFetching = false }
    
    await taxiChatUseCase.fetchChats(before: date)
  }

  private func groupChats(_ chats: [TaxiChat], currentUserID: String) -> [TaxiChatGroup] {
    guard !chats.isEmpty else { return [] }

    var result: [TaxiChatGroup] = []
    var currentGroup: [TaxiChat] = []

    func flushGroup() {
      if !currentGroup.isEmpty {
        let isMe = currentGroup.first?.authorID == currentUserID
        result.append(TaxiChatGroup(chatGroup: currentGroup, isMe: isMe))
        currentGroup = []
      }
    }

    let calendar = Calendar.current

    for (_, chat) in chats.enumerated() {
      if chat.type == .entrance || chat.type == .exit {
        flushGroup()
        result.append(TaxiChatGroup(chatGroup: [chat], isMe: chat.authorID == currentUserID))
        continue
      }

      if currentGroup.isEmpty {
        currentGroup.append(chat)
        continue
      }

      let lastChat = currentGroup.last!
      let sameAuthor = chat.authorID == lastChat.authorID
      let sameMinute = calendar.isDate(chat.time, equalTo: lastChat.time, toGranularity: .minute)

      if sameAuthor && sameMinute {
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
