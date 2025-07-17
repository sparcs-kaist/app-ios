//
//  TaxiChatBubble.swift
//  soap
//
//  Created by Soongyu Kwon on 17/07/2025.
//

import SwiftUI

struct TaxiChatBubble: View {
  let chat: TaxiChat
  let showTip: Bool
  let isSentByMe: Bool

  var body: some View {
    HStack {
      if isSentByMe {
        Spacer(minLength: 130)
      } else {
        
      }

      Text(chat.content)
        .padding(12)
        .background(
          isSentByMe ? .accent : .secondarySystemBackground,
          in: .rect(
            topLeadingRadius: 24,
            bottomLeadingRadius: !isSentByMe && showTip ? 4 : 24,
            bottomTrailingRadius: isSentByMe && showTip ? 4 : 24,
            topTrailingRadius: 24
          )
        )
        .foregroundStyle(isSentByMe ? .white : .primary)

      if !isSentByMe {
        Spacer(minLength: 130)
      }
    }
  }
}

#Preview {
  let chat = TaxiChat(
    roomID: "",
    type: .text,
    authorID: "",
    authorName: "testuser",
    authorProfileURL: nil,
    authorIsWithdrew: false,
    content: "this is a test ad dasdf eioqe qfdaa sdfasdfa sodfa asdfwo qwojef oqjweof qowjf ",
    time: Date(),
    isValid: false,
    inOutNames: []
  )
  let short = TaxiChat(
    roomID: "",
    type: .text,
    authorID: "",
    authorName: "testuser",
    authorProfileURL: nil,
    authorIsWithdrew: false,
    content: "this is a test",
    time: Date(),
    isValid: false,
    inOutNames: []
  )

  VStack(spacing: 4) {
    TaxiChatBubble(chat: short, showTip: true, isSentByMe: false)
    TaxiChatBubble(chat: short, showTip: false, isSentByMe: true)
    TaxiChatBubble(chat: chat, showTip: true, isSentByMe: true)
  }
}
