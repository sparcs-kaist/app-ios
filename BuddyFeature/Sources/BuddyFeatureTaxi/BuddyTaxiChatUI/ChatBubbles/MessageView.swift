//
//  MessageView.swift
//  BuddyTaxiChatUI
//
//  Created by Soongyu Kwon on 15/02/2026.
//

import SwiftUI
import BuddyDomain
import NukeUI

struct MessageView<Content: View>: View {
  @ViewBuilder let content: () -> Content

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

        content()
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
