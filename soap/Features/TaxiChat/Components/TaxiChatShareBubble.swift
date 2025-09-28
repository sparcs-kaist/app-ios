//
//  TaxiChatShareBubble.swift
//  soap
//
//  Created by Soongyu Kwon on 01/08/2025.
//

import SwiftUI

struct TaxiChatShareBubble: View {
  let room: TaxiRoom
  let share: (() -> Void)

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Share now and create a pleasant taxi-sharing experience!")
      ShareLink(item: URL(string: "https://taxi.dev.sparcs.org/invite/" + room.id)!, message: Text(LocalizedStringResource("🚕 Looking for someone to ride with on \(room.departAt.formattedString) from \(room.source.title) to \(room.destination.title)! 🚕"))) {
        Label("Share", systemImage: "square.and.arrow.up")
          .frame(maxWidth: .infinity)
      }
      .fontWeight(.medium)
      .buttonStyle(.glassProminent)
    }
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
    isWithdrawn: false
  ) {
    TaxiChatShareBubble(room: TaxiRoom.mock) {
      logger.debug("share sheet goes here")
    }
  }
  .padding()
}
