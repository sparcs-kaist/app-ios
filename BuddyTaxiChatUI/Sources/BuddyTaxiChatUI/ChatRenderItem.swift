//
//  ChatRenderItem.swift
//  BuddyTaxiChatUI
//
//  Created by Soongyu Kwon on 14/02/2026.
//

import Foundation
import BuddyDomain
import Playgrounds

enum ChatRenderItem: Hashable {
  case daySeparator(Date)
  case systemEvent(id: UUID, chat: TaxiChat)
  case bubble(
    id: UUID,
    chat: TaxiChat,
    position: ChatBubblePosition,
    isMine: Bool,
    showName: Bool,
    showAvatar: Bool,
    showTime: Bool
  )
}

struct ChatRenderItemBuilder {
  let policy: ChatGroupingPolicy
  let positionResolver: ChatBubblePositionResolver
  let calendar: Calendar = .current

  func build(chats: [TaxiChat], myUserID: String?) -> [ChatRenderItem] {
    let sorted = chats.sorted {
      if $0.time == $1.time { return $0.id.uuidString < $1.id.uuidString }
      return $0.time < $1.time
    }

    var items: [ChatRenderItem] = []
    var cluster: [TaxiChat] = []
    var lastDay: Date?

    func flushCluster() {
      guard !cluster.isEmpty else { return }
      for (idx, chat) in cluster.enumerated() {
        let isMine = chat.authorID == myUserID
        let pos = positionResolver.resolve(index: idx, count: cluster.count)
        items.append(
          .bubble(
            id: chat.id,
            chat: chat,
            position: pos,
            isMine: isMine,
            showName: !isMine && idx == 0,
            showAvatar: !isMine && idx == cluster.count - 1,
            showTime: idx == cluster.count - 1
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

      if policy.isSystemEvent(chat) || !policy.isBubbleEligible(chat) {
        flushCluster()
        items.append(.systemEvent(id: chat.id, chat: chat))
        continue
      }

      if let prev = cluster.last, policy.canGroup(prev, chat, myUserID: myUserID) {
        cluster.append(chat)
      } else {
        flushCluster()
        cluster.append(chat)
      }
    }

    flushCluster()
    return items
  }
}


#Playground {
  let mock: [TaxiChat] = TaxiChat.mockList
  let builder = ChatRenderItemBuilder(policy: TaxiGroupingPolicy(), positionResolver: ChatBubblePositionResolver())
  let items = builder.build(chats: mock, myUserID: "user1")
}
