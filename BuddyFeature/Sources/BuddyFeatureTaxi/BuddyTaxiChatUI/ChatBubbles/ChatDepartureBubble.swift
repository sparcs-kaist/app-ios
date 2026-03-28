//
//  ChatDepartureBubble.swift
//  soap
//
//  Created by Soongyu Kwon on 18/07/2025.
//

import Foundation
import SwiftUI
import BuddyDomain

struct ChatDepartureBubble: View {
  let room: TaxiRoom

  @Environment(\.openURL) private var openURL
  @State private var showAlert: Bool = false

  var body: some View {
    VStack(alignment: .leading) {
      Text("⏰ It's 15 minutes before your taxi leaves! If everyone's gathered, go ahead and call the taxi to head out together.", bundle: .module)
      
      if let emojiIdentifier = room.emojiIdentifier {
        VStack(alignment: .center) {
          Text("Room Identifier", bundle: .module)
            .fontWeight(.bold)
            .font(.headline)
          Text(emojiIdentifier.emoji)
            .font(.largeTitle)
          Text("Please check the room identifier.", bundle: .module)
            .font(.caption)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
          RoundedRectangle(cornerRadius: 8)
            .fill(.background)
        )
      }

      Button(action: {
        showAlert = true
      }, label: {
        Label(String(localized: "Call Taxi", bundle: .module), systemImage: "car.fill")
          .frame(maxWidth: .infinity)
      })
      .fontWeight(.medium)
      .buttonStyle(.glassProminent)
    }
    .padding(12)
    .background(Color.secondarySystemBackground, in: .rect(cornerRadius: 24))
    .alert(
      "Call Taxi",
      isPresented: $showAlert,
      actions: {
        Button(String(localized: "Open Kakao T", bundle: .module), role: .confirm) {
          if let url = TaxiDeepLinkHelper.kakaoTURL(source: room.source, destination: room.destination) {
            openURL(url)
          }
        }
        Button(String(localized: "Open Uber", bundle: .module), role: .confirm) {
          if let url = TaxiDeepLinkHelper.uberURL(source: room.source, destination: room.destination) {
            openURL(url)
          }
        }
        Button(String(localized: "Cancel", bundle: .module), role: .cancel) { }
      },
      message: {
        Text(
          "You can launch the taxi app with the departure and destination already set. Once everyone has gathered at the departure point, press the button to call a taxi from \(room.source.title.localized()) to \(room.destination.title.localized())."
        )
      }
    )
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
//    TaxiDepartureBubble(room: TaxiRoom.mock)
//  }
//  .padding()
//}
//
