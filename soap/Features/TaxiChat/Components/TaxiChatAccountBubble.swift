//
//  TaxiChatAccountBubble.swift
//  soap
//
//  Created by Soongyu Kwon on 01/08/2025.
//

import SwiftUI

struct TaxiChatAccountBubble: View {
  let content: String
  let isMe: Bool
  let markAsSent: (() -> Void)

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("SETTLEMENT")
        .font(.footnote)
        .fontWeight(.semibold)
        .foregroundStyle(.secondary)

      let parts = content.split(separator: " ", maxSplits: 1)
      if parts.count == 2 {
        let bank = parts[0]
        let accountNumber = parts[1]
        // use bank and accountNumber here

        HStack(spacing: 4) {
          Image(systemName: "wonsign.bank.building")
            .fontWeight(.semibold)
          Text(bank)
            .fontWeight(.semibold)
          Text(accountNumber)
        }
      } else {
        Text("Failed to parse account information.")
      }

      Button(action: {
        
      }, label: {
        Label("Mark as Sent", systemImage: "checkmark")
          .frame(maxWidth: .infinity)
      })
      .fontWeight(.medium)
      .buttonStyle(.glassProminent)
      .disabled(isMe)
    }
    .padding(12)
    .background(Color.secondarySystemBackground, in: .rect(cornerRadius: 24))
    .contextMenu {
      Button {
        let parts = content.split(separator: " ", maxSplits: 1)
        UIPasteboard.general.string = String(parts[1])
      } label: {
        Label("Copy Account Info", systemImage: "doc.on.doc")
      }
    }
  }
}

#Preview {
  TaxiChatUserWrapper(
    authorID: nil,
    authorName: nil,
    authorProfileImageURL: nil,
    date: Date(),
    isMe: false,
    isGeneral: false,
    isWithdrawn: false
  ) {
    TaxiChatAccountBubble(content: "KB국민 90415338958", isMe: false) {
      logger.debug("mark as sent")
    }
  }
  .padding()
}
