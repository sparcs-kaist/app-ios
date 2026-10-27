//
//  MessageView.swift
//  BuddyTaxiChatUI
//
//  Created by Soongyu Kwon on 15/02/2026.
//

import Foundation
import SwiftUI
import BuddyDomain
import NukeUI

/// Widths that keep messages readable when the chat spans a wide display —
/// an iPad, or an unfolded iPhone Duo — rather than a phone's width. Below
/// these widths, as on an iPhone in portrait, they change nothing.
enum ChatBubbleMetrics {
  /// The whole row, avatar and read receipt included. Leaves a text bubble
  /// about 450 to 490 points: lines of a comfortable length.
  static let maxRowWidth: CGFloat = 560
  /// Content of bubbles that carry a full-width button, so it stays a button
  /// rather than a banner.
  static let maxActionBubbleWidth: CGFloat = 360
}

struct MessageView<Content: View>: View {
  let chat: TaxiChat
  let kind: TaxiChat.ChatType
  let sender: SenderInfo
  let position: ChatBubblePosition
  let readCount: Int
  let metadata: MetadataVisibility
  /// The sender as a rider of the room, to show who they are from their photo. Nil for the taxi
  /// bot and for anyone who has left.
  var rider: TaxiParticipant? = nil

  @ViewBuilder let content: () -> Content

  @State private var showPopover: Bool = false
  @State private var showRiderCard: Bool = false

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
        avatar
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
                Text("Members with this badge can resolve issues through SPARCS mediation when problems arise.", bundle: .module)
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
    // The row already fills its width through its spacer, so on a narrow
    // display these frames are no-ops; on a wide one the capped row keeps to
    // its sender's side.
    .frame(maxWidth: ChatBubbleMetrics.maxRowWidth, alignment: sender.isMine ? .trailing : .leading)
    .frame(maxWidth: .infinity, alignment: sender.isMine ? .trailing : .leading)
  }

  /// The sender's photo, which shows who they are when they are still riding.
  @ViewBuilder
  private var avatar: some View {
    if let rider, metadata.showAvatar {
      Button {
        showRiderCard = true
      } label: {
        ChatAvatarImage(sender: sender)
      }
      .buttonStyle(.plain)
      .accessibilityLabel(rider.nickname)
      .popover(isPresented: $showRiderCard) {
        TaxiRiderCard(participant: rider)
          .presentationCompactAdaptation(.popover)
      }
    } else {
      ChatAvatarImage(sender: sender)
    }
  }

  private var authorNameplace: some View {
    Group {
      if sender.isWithdrew {
        Text("Unknown", bundle: .module)
      } else if let name = sender.name {
        Text(name)
      } else if sender.id == nil {
        Text("Taxi Bot", bundle: .module)
      } else {
        Text("Unknown", bundle: .module)
      }
    }
  }
}
