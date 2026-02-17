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
  let chat: TaxiChat
  let kind: TaxiChat.ChatType
  let sender: SenderInfo
  let position: ChatBubblePosition
  let readCount: Int
  let metadata: MetadataVisibility

  @ViewBuilder let content: () -> Content

  @State private var showPopover: Bool = false

  var body: some View {
    HStack(alignment: .bottom, spacing: 4) {
      if sender.isMine {
        Spacer(minLength: 40)
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
          HStack(spacing: 4) {
            authorNameplace
            Image(systemName: "phone.circle.fill")
              .foregroundStyle(Color.accentColor)
              .onTapGesture {
                showPopover = true
              }
              .popover(isPresented: $showPopover) {
                Text("Members with this badge can resolve issues through SPARCS mediation when problems arise.")
                  .font(.caption)
                  .padding()
                  .frame(width: 250)
                  .presentationCompactAdaptation(.popover)
              }
          }
          .font(.caption)
          .fontWeight(.medium)
        }

        HStack(alignment: .bottom, spacing: 4) {
          content()

          if !sender.isMine {
            ChatReadReceipt(
              readCount: readCount,
              showTime: metadata.showTime,
              time: chat.time,
              alignment: .leading
            )
            Spacer(minLength: 40)
          }
        }
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
