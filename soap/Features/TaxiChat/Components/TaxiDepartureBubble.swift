//
//  TaxiDepartureBubble.swift
//  soap
//
//  Created by Soongyu Kwon on 18/07/2025.
//

import SwiftUI
import BuddyDomain

struct TaxiDepartureBubble: View {
  let room: TaxiRoom

  @Environment(\.openURL) private var openURL
  @State private var showAlert: Bool = false

  var body: some View {
    VStack {
      Text("⏰ It's 15 minutes before your taxi leaves! If everyone's gathered, go ahead and call the taxi to head out together.")

      Button(action: {
        showAlert = true
      }, label: {
        Label("Call Taxi", systemImage: "car.fill")
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
        Button("Open Kakao T", role: .confirm) {
          openKakaoT()
        }
        Button("Open Uber", role: .confirm) {
          openUber()
        }
        Button("Cancel", role: .cancel) { }
      },
      message: {
        Text(
          "You can launch the taxi app with the departure and destination already set. Once everyone has gathered at the departure point, press the button to call a taxi from \(room.source.title.localized()) to \(room.destination.title.localized())."
        )
      }
    )
  }

  private func openKakaoT() {
    if let url = URL(
      string: "kakaot://taxi/set?dest_lng=\(room.destination.longitude)&dest_lat=\(room.destination.latitude)&origin_lng=\(room.source.longitude)&origin_lat=\(room.source.latitude)"
    ) {
      openURL(url)
    }
  }

  private func openUber() {
    if let url = URL(
      string: "uber://?action=setPickup&client_id=a&&pickup[latitude]=\(room.source.latitude)&pickup[longitude]=\(room.source.longitude)&&dropoff[latitude]=\(room.destination.latitude)&dropoff[longitude]=\(room.destination.longitude)"
    ) {
      openURL(url)
    }
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
    TaxiDepartureBubble(room: TaxiRoom.mock)
  }
  .padding()
}

