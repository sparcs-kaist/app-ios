//
//  ChatPaymentBubble.swift
//  soap
//
//  Created by Soongyu Kwon on 25/07/2025.
//

import SwiftUI

struct ChatPaymentBubble: View {
  var body: some View {
    Label("I sent the money!", systemImage: "paperplane.fill")
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
//    TaxiChatPaymentBubble()
//  }
//  .padding()
//}
