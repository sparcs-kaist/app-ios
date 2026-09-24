//
//  ChatSettlementBubble.swift
//  soap
//
//  Created by Soongyu Kwon on 20/07/2025.
//

import Foundation
import SwiftUI

private struct SettlementMeta: Decodable {
  let total: Int
  let perPerson: Int
  let participantCount: Int
}

struct ChatSettlementBubble: View {
  let content: String

  private var settlementMeta: SettlementMeta? {
    guard let data = content.data(using: .utf8) else { return nil }
    return try? JSONDecoder().decode(SettlementMeta.self, from: data)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Label(String(localized: "I paid for the taxi!", bundle: .module), systemImage: "creditcard.fill")

      if let settlementMeta {
        HStack(alignment: .top, spacing: 20) {
          amountColumn(
            title: String(localized: "Total fare", bundle: .module),
            amount: settlementMeta.total,
            alignment: .leading
          )

          amountColumn(
            title: String(localized: "Per person", bundle: .module),
            amount: settlementMeta.perPerson,
            alignment: .trailing
          )
        }

        Text("\(settlementMeta.participantCount) people", bundle: .module)
          .font(.caption)
          .opacity(0.85)
      }
    }
    .padding(12)
    .background(
      Color.accentColor,
      in: .rect(
        topLeadingRadius: 24,
        bottomLeadingRadius: 24,
        bottomTrailingRadius: 24,
        topTrailingRadius: 24
      )
    )
    .foregroundStyle(.white)
  }

  private func amountColumn(title: String, amount: Int, alignment: HorizontalAlignment) -> some View {
    VStack(alignment: alignment, spacing: 2) {
      Text(title)
        .font(.caption)
        .opacity(0.85)
      Text("₩" + amount.formatted(.number.grouping(.automatic)))
        .font(.subheadline)
        .fontWeight(.semibold)
    }
  }
}

//#Preview {
//  TaxiChatUserWrapper(
//    authorID: nil,
//    authorName: nil,
//    authorProfileImageURL: nil,
//    date: Date(),
//    isMe: false,
//    isGeneral: false,
//    isWithdrawn: false,
//    badge: true
//  ) {
//    TaxiChatSettlementBubble()
//  }
//  .padding()
//}
