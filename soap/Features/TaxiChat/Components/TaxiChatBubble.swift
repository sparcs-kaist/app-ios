//
//  TaxiChatBubble.swift
//  soap
//
//  Created by Soongyu Kwon on 17/07/2025.
//

import SwiftUI

private struct ChatTimeKey: EnvironmentKey {
  static let defaultValue: Date? = nil
}

extension EnvironmentValues {
  var chatTime: Date? {
    get { self[ChatTimeKey.self] }
    set { self[ChatTimeKey.self] = newValue }
  }
}

struct TaxiChatBubble: View {
  @Environment(\.chatTime) private var time: Date?

  let content: String
  let showTip: Bool
  let isMe: Bool

  var body: some View {
    HStack(alignment: .bottom, spacing: 4) {
      if showTip && isMe,
         let time = time {
        Text(time.formattedTime)
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

      if showTip && !isMe,
         let time = time {
        Text(time.formattedTime)
          .font(.caption2)
          .foregroundStyle(.secondary)
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
