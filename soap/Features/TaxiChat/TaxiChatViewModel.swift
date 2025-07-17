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

  private func groupChats(_ chats: [TaxiChat], currentUserID: String) -> [TaxiChatGroup] {
    guard !chats.isEmpty else { return [] }

    var result: [TaxiChatGroup] = []
    var currentGroup: [TaxiChat] = [chats[0]]

    for i in 1..<chats.count {
      let current = chats[i]
      let previous = chats[i - 1]

      let isBoundaryChat: Bool = {
        return current.type == .entrance || current.type == .exit
      }()

      if isBoundaryChat {
        if !currentGroup.isEmpty {
          result.append(TaxiChatGroup(chatGroup: currentGroup, isMe: currentGroup.first?.authorID == currentUserID))
          currentGroup = []
        }
        result.append(TaxiChatGroup(chatGroup: [current], isMe: current.authorID == currentUserID))
      } else if current.authorID == previous.authorID {
        currentGroup.append(current)
      } else {
        if !currentGroup.isEmpty {
          result.append(TaxiChatGroup(chatGroup: currentGroup, isMe: currentGroup.first?.authorID == currentUserID))
        }
        currentGroup = [current]
      }
    }

    // Append the final group
    if !currentGroup.isEmpty {
      result.append(TaxiChatGroup(chatGroup: currentGroup, isMe: currentGroup.first?.authorID == currentUserID))
    }

    return result
  }
}
