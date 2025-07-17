//
//  TaxiChatBubble.swift
//  soap
//
//  Created by Soongyu Kwon on 17/07/2025.
//

import SwiftUI

struct TaxiChatBubble: View {
  let content: String
  let date: Date
  let showTip: Bool
  let isMe: Bool

  var body: some View {
    HStack(alignment: .bottom) {
      if showTip && isMe {
        Text(date.formattedTime)
          .font(.caption2)
          .foregroundStyle(.secondary)
      }

      Text(content)
        .padding(12)
        .background(
          isMe ? .accent : .secondarySystemBackground,
          in: .rect(
            topLeadingRadius: 24,
            bottomLeadingRadius: !isMe && showTip ? 4 : 24,
            bottomTrailingRadius: isMe && showTip ? 4 : 24,
            topTrailingRadius: 24
          )
        )
        .foregroundStyle(isMe ? .white : .primary)

      if showTip && !isMe {
        Text(date.formattedTime)
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
    }
  }
}

#Preview {
  VStack(spacing: 4) {
    TaxiChatBubble(content: "this is a test", date: Date(), showTip: true, isMe: false)
    TaxiChatBubble(content: "this is a test", date: Date(), showTip: true, isMe: true)
    TaxiChatBubble(content: "this is a test", date: Date(), showTip: false, isMe: false)
    TaxiChatBubble(content: "this is a test", date: Date(), showTip: true, isMe: false)
    TaxiChatBubble(content: "this is a test", date: Date(), showTip: false, isMe: true)
    TaxiChatBubble(content: "this is a test ad dasdf eioqe qfdaa sdfasdfa sodfa asdfwo qwojef oqjweof qowjf ", date: Date(), showTip: true, isMe: true)
  }
  .padding()
}
