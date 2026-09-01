//
//  ChatShareBubble.swift
//  soap
//
//  Created by Soongyu Kwon on 01/08/2025.
//

import Foundation
import SwiftUI
import BuddyDomain

struct ChatShareBubble: View {
  let room: TaxiRoom

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Share now and create a pleasant taxi-sharing experience!", bundle: .module)
      ShareLink(item: Constants.taxiInviteURL.appending(path: room.id), message: Text("🚕 Looking for someone to ride with on \(room.departAt.formattedString) from \(room.source.title) to \(room.destination.title)! 🚕", bundle: .module)) {
        Label(String(localized: "Share", bundle: .module), systemImage: "square.and.arrow.up")
          .frame(maxWidth: .infinity)
      }
      .fontWeight(.medium)
      .buttonStyle(.glassProminent)
    }
    .padding(12)
    .background(Color.secondarySystemBackground, in: .rect(cornerRadius: 24))
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
//    TaxiChatShareBubble(room: TaxiRoom.mock)
//  }
//  .padding()
//}
