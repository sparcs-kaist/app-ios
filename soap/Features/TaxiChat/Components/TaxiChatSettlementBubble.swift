//
//  TaxiChatSettlementBubble.swift
//  soap
//
//  Created by Soongyu Kwon on 20/07/2025.
//

import SwiftUI

struct TaxiChatSettlementBubble: View {
  var body: some View {
    Label("I paid for the taxi!", systemImage: "creditcard.fill")
      .padding(12)
      .background(
        .accent,
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

#Preview {
  TaxiChatUserWrapper(
    authorID: nil,
    authorName: nil,
    authorProfileImageURL: nil,
    date: Date(),
    isMe: false,
    isGeneral: false
  ) {
    TaxiChatSettlementBubble()
  }
  .padding()
}
