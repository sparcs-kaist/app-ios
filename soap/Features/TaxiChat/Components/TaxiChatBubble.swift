//
//  TaxiChatBubble.swift
//  soap
//
//  Created by Soongyu Kwon on 17/07/2025.
//

import SwiftUI

struct TaxiChatBubble: View {
  let content: String
  let showTip: Bool
  let isMe: Bool

  var body: some View {
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
      .contextMenu {
        Button("Copy", systemImage: "doc.on.doc") {
          UIPasteboard.general.string = content
        }
      }
  }
}

#Preview {
  VStack(spacing: 4) {
    TaxiChatBubble(content: "this is a test", showTip: true, isMe: false)
    TaxiChatBubble(content: "this is a test", showTip: true, isMe: true)
    TaxiChatBubble(content: "this is a test", showTip: false, isMe: false)
    TaxiChatBubble(content: "this is a test", showTip: true, isMe: false)
    TaxiChatBubble(content: "this is a test", showTip: false, isMe: true)
    TaxiChatBubble(content: "this is a test ad dasdf eioqe qfdaa sdfasdfa sodfa asdfwo qwojef oqjweof qowjf ", showTip: true, isMe: true)
  }
  .padding()
}
