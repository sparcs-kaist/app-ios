//
//  ChatRenderItem.swift
//  BuddyTaxiChatUI
//
//  Created by Soongyu Kwon on 14/02/2026.
//

import Foundation
import BuddyDomain
import Playgrounds

enum ChatRenderItem: Hashable, Identifiable {
  case daySeparator(Date)
  case systemEvent(
    id: UUID,
    chat: TaxiChat
  )
  case message(
    id: UUID,
    chat: TaxiChat,
    kind: TaxiChat.ChatType,
    sender: SenderInfo,
    position: ChatBubblePosition,
    metadata: MetadataVisibility
  )

  var id: AnyHashable {
    switch self {
    case .daySeparator(let date):
      return AnyHashable("day-\(date.timeIntervalSince1970)")
    case .systemEvent(let id, _):
      return AnyHashable("system-\(id)")
    case .message(let id, _, _, _, _, _):
      return AnyHashable("message-\(id)")
    }
  }
}

struct ChatRenderItemBuilder {
  let policy: ChatGroupingPolicy
  let positionResolver: ChatBubblePositionResolver
  let presentationPolicy: MessagePresentationPolicy
  let calendar: Calendar = .current

  func build(chats: [TaxiChat], myUserID: String?) -> [ChatRenderItem] {
    let sorted = chats.sorted {
      if $0.time == $1.time { return $0.id.uuidString < $1.id.uuidString }
      return $0.time < $1.time
    }

    var items: [ChatRenderItem] = []
    var cluster: [TaxiChat] = []
    var lastDay: Date?

    func sender(of chat: TaxiChat) -> SenderInfo {
      SenderInfo(
        id: chat.authorID,
        name: chat.authorName,
        avatarURL: chat.authorProfileURL,
        isMine: chat.authorID == myUserID,
        isWithdrew: chat.authorIsWithdrew ?? false
      )
    }

    func groupingBehavior(of chat: TaxiChat) -> GroupingBehavior {
      if policy.isBubbleEligible(chat) && !policy.isSystemEvent(chat) {
        return .mergeable
      }
      return .standalone
    }

    func flushCluster() {
      guard !cluster.isEmpty else { return }

      for (idx, chat) in cluster.enumerated() {
        let k = chat.type
        let s = sender(of: chat)
        let pos = positionResolver.resolve(index: idx, count: cluster.count)
        let meta = presentationPolicy.metadata(
          kind: k,
          isMine: s.isMine,
          indexInCluster: idx,
          clusterCount: cluster.count,
          isStandalone: false
        )

        items.append(
          .message(
            id: chat.id,
            chat: chat,
            kind: k,
            sender: s,
            position: pos,
            metadata: meta
          )
        )
      }

      cluster.removeAll(keepingCapacity: true)
    }

    for chat in sorted {
      let day = calendar.startOfDay(for: chat.time)
      if lastDay == nil || day != lastDay {
        flushCluster()
        items.append(.daySeparator(day))
        lastDay = day
      }

      switch groupingBehavior(of: chat) {
      case .standalone:
        flushCluster()

        let k = chat.type
        let s = sender(of: chat)
        let meta = presentationPolicy.metadata(
          kind: k,
          isMine: s.isMine,
          indexInCluster: 0,
          clusterCount: 1,
          isStandalone: true
        )

        if k == .entrance || k == .exit {
          items.append(
            .systemEvent(id: chat.id, chat: chat)
          )
        } else {
          items.append(
            .message(
              id: chat.id,
              chat: chat,
              kind: k,
              sender: s,
              position: .single,
              metadata: meta
            )
          )
        }

      case .mergeable:
        if let prev = cluster.last, policy.canGroup(prev, chat, myUserID: myUserID) {
          cluster.append(chat)
        } else {
          flushCluster()
          cluster.append(chat)
        }
      }
    }

    flushCluster()
    return items
  }
}

#Playground {
  let mock: [TaxiChat] = TaxiChat.mockList
  let builder = ChatRenderItemBuilder(
    policy: TaxiGroupingPolicy(),
    positionResolver: ChatBubblePositionResolver(),
    presentationPolicy: DefaultMessagePresentationPolicy()
  )
  _ = builder.build(chats: mock, myUserID: "user2")
}

