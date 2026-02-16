//
//  MessageView.swift
//  BuddyTaxiChatUI
//
//  Created by Soongyu Kwon on 15/02/2026.
//

import SwiftUI
import BuddyDomain
import NukeUI

struct MessageView: View {
  let chat: TaxiChat
  let kind: TaxiChat.ChatType
  let sender: SenderInfo
  let position: ChatBubblePosition
  let readCount: Int
  let metadata: MetadataVisibility

  var body: some View {
    HStack(alignment: .bottom) {
      if sender.isMine {
        Spacer()
        ChatReadReceipt(
          readCount: readCount,
          showTime: metadata.showTime,
          time: chat.time,
          alignment: .trailing
        )
      } else {
        ChatAvatarImage(sender: sender)
          .opacity(metadata.showAvatar ? 1 : 0)
      }

      VStack(alignment: .leading, spacing: 4) {
        if metadata.showName {
          authorNameplace
            .font(.caption)
            .fontWeight(.medium)
        }

        bubble
      }

      if !sender.isMine {
        ChatReadReceipt(
          readCount: readCount,
          showTime: metadata.showTime,
          time: chat.time,
          alignment: .leading
        )
        Spacer()
      }
    }
  }

  @ViewBuilder
  var bubble: some View {
    switch chat.type {
    case .text:
      ChatBubble(chat: chat, position: position, isMine: sender.isMine)
    default:
      Text("not implemented")
    }
  }

  private var authorNameplace: some View {
    Group {
      if sender.isWithdrew {
        Text("Unknown")
      } else if let name = sender.name {
        Text(name)
      } else if sender.id == nil {
        Text("Taxi Bot")
      } else {
        Text("Unknown")
      }
    }
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

  ScrollView {
    LazyVStack {
      ForEach(items, id: \.self) { item in
        switch item {
        case .message(let id, let chat, let kind, let sender, let position, let metadata):
          MessageView(chat: chat, kind: kind, sender: sender, position: position, readCount: 2, metadata: metadata)
        default:
          EmptyView()
        }
      }
    }
    .padding()
  }
}
