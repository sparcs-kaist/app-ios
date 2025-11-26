//
//  TaxiArrivalBubble.swift
//  soap
//
//  Created by Soongyu Kwon on 18/07/2025.
//

import SwiftUI

struct TaxiArrivalBubble: View {
  var body: some View {
    Text("There are users who have not yet requested the settlement or have not completed the payment.\n\nPlease tap the **+ button** at the bottom left and press **Request Settlement** or **Send Payment** to complete the settlement request or payment.")
      .padding(12)
      .background(Color.secondarySystemBackground, in: .rect(cornerRadius: 24))
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
    isWithdrawn: false,
    badge: true
  ) {
    TaxiArrivalBubble()
  }
  .padding()
}
