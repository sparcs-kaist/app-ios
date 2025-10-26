//
//  TaxiChatAccountBubble.swift
//  soap
//
//  Created by Soongyu Kwon on 01/08/2025.
//

import SwiftUI

struct TaxiChatAccountBubble: View {
  let content: String
  let isCommitPaymentAvailable: Bool
  let markAsSent: (() -> Void)

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Settlement")
        .textCase(.uppercase)
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
            .resizable()
            .aspectRatio(contentMode: .fit)
            .fixedSize()
            .fontWeight(.semibold)
          Text(bank)
            .fontWeight(.semibold)
          Text(accountNumber)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.75)
        .scaledToFit()
      } else {
        Text("Failed to parse account information.")
      }

      Button(action: {
        markAsSent()
      }, label: {
        if isCommitPaymentAvailable {
          Label("Send Payment", systemImage: "wonsign.circle")
            .frame(maxWidth: .infinity)
        } else {
          Label("Already Sent", systemImage: "checkmark")
            .frame(maxWidth: .infinity)
        }
      })
      .fontWeight(.medium)
      .buttonStyle(.glassProminent)
      .disabled(!isCommitPaymentAvailable)
    }
    .padding(12)
    .background(Color.secondarySystemBackground, in: .rect(cornerRadius: 24))
    .contextMenu {
      Button("Copy Account Info", systemImage: "doc.on.doc") {
        let parts = content.split(separator: " ", maxSplits: 1)
        UIPasteboard.general.string = String(parts[1])
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
    TaxiChatAccountBubble(content: "KB국민 90415338958", isCommitPaymentAvailable: false) {
      logger.debug("mark as sent")
    }
  }
  .padding()
}
