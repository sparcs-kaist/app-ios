//
//  ChatList.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 17/02/2026.
//

import SwiftUI
import BuddyDomain

struct ChatList: View {
  let items: [ChatRenderItem]
  let room: TaxiRoom
  let user: TaxiUser?

  var body: some View {
    ScrollViewReader { reader in
      List(items) { item in
        chatItem(item)
      }
      .listStyle(.plain)
      .environment(\.defaultMinListRowHeight, 0)
      .onAppear {
        reader.scrollTo(items.last?.id, anchor: .bottom)
      }
      .scrollDismissesKeyboard(.interactively)
    }
  }

  @ViewBuilder
  func chatItem(_ item: ChatRenderItem) -> some View {
    Group {
      switch item {
      case .daySeparator(let date):
        ChatDaySeperator(date: date)
          .listRowInsets(.init(top: 8, leading: 8, bottom: 8, trailing: 8))
      case .systemEvent(_, let chat):
        ChatGeneralMessage(authorName: chat.authorName, type: chat.type)
          .listRowInsets(.init(top: 8, leading: 8, bottom: 8, trailing: 8))
      case .message(_, let chat, let kind, let sender, let position, let metadata):
        MessageView(
          chat: chat,
          kind: kind,
          sender: sender,
          position: position,
          readCount: readCount(for: chat),
          metadata: metadata
        ) {
          switch kind {
          case .text:
            ChatBubble(chat: chat, position: position, isMine: sender.isMine)
          case .s3img:
            ChatImageBubble(id: chat.content)
          case .departure:
            ChatDepartureBubble(room: room)
          case .arrival:
            ChatArrivalBubble()
          case .settlement:
            ChatSettlementBubble()
          case .payment:
            ChatPaymentBubble()
          case .account:
            ChatAccountBubble(content: chat.content, isCommitPaymentAvailable: isCommitSettlementAvailable) {
//              showPayMoneyAlert = true
            }
          case .share:
            ChatShareBubble(room: room)
          default:
            Text("not supported")
          }
        }
        .listRowInsets(
          .init(
            top: position == .middle || position == .bottom ? 4 : 8,
            leading: 8,
            bottom: 0,
            trailing: 8
          )
        )
      }
    }
    .listRowSeparator(.hidden)
  }

  private var isCommitSettlementAvailable: Bool {
    return room.isDeparted && room.settlementTotal == 0
  }

  private func readCount(for chat: TaxiChat) -> Int {
    let otherParticipants = room.participants.filter {
      $0.id != user?.oid
    }
    return otherParticipants.count(where: { $0.readAt <= chat.time })
  }
}


#Preview {
  let mock: [TaxiChat] = TaxiChat.mockList
  let builder = ChatRenderItemBuilder(
    policy: TaxiGroupingPolicy(),
    positionResolver: ChatBubblePositionResolver(),
    presentationPolicy: DefaultMessagePresentationPolicy()
  )
  let items = builder.build(chats: mock, myUserID: "user2")
  ChatList(items: items, room: TaxiRoom.mock, user: TaxiUser.mock)
}
