//
//  ChatAccountBubble.swift
//  soap
//
//  Created by Soongyu Kwon on 01/08/2025.
//

import Foundation
import SwiftUI

struct ChatAccountBubble: View {
  let content: String
  let isCommitPaymentAvailable: Bool
  let markAsSent: (() -> Void)

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(String(localized: "Settlement", bundle: .module))
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
        Text(String(localized: "Failed to parse account information.", bundle: .module))
      }

      Button(action: {
        markAsSent()
      }, label: {
        if isCommitPaymentAvailable {
          Label(String(localized: "Send Payment", bundle: .module), systemImage: "wonsign.circle")
            .frame(maxWidth: .infinity)
        } else {
          Label(String(localized: "Already Sent", bundle: .module), systemImage: "checkmark")
            .frame(maxWidth: .infinity)
        }
      })
      .fontWeight(.medium)
      .buttonStyle(.glassProminent)
      .disabled(!isCommitPaymentAvailable)
    }
    .padding(12)
    .background(Color.secondarySystemBackground, in: .rect(cornerRadius: 24))
//    .contextMenu {
//      Button(String(localized: "Copy Account Info", bundle: .module), systemImage: "doc.on.doc") {
//        let parts = content.split(separator: " ", maxSplits: 1)
//        UIPasteboard.general.string = String(parts[1])
//      }
//    }
  }
}
