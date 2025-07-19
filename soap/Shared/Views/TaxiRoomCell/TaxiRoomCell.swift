//
//  TaxiRoomCell.swift
//  soap
//
//  Created by Soongyu Kwon on 12/07/2025.
//

import SwiftUI

struct TaxiRoomCell: View {
  let room: TaxiRoom

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 4) {
          Label(room.source.title.localized(), systemImage: "location.fill")
          Label(room.destination.title.localized(), systemImage: "flag.pattern.checkered")
        }
        .fontWeight(.medium)

        Spacer()

        TaxiParticipantsIndicator(participants: room.participants.count, capacity: room.capacity)
      }

      HStack {
        Text(room.departAt.relativeTimeString)
        Divider()
        Text(room.title)
      }
      .fixedSize()
      .font(.footnote)
      .foregroundStyle(.secondary)
    }
    .padding()
    .background(Color.systemBackground, in: .rect(cornerRadius: 28))
  }
}

#Preview {
  let room: TaxiRoom = TaxiRoom.mock
  ZStack {
    Color.secondarySystemBackground
    TaxiRoomCell(room: room)
      .padding()
  }
  .ignoresSafeArea()
}
