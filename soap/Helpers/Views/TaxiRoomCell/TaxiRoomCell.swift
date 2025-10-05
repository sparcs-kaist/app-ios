//
//  TaxiRoomCell.swift
//  soap
//
//  Created by Soongyu Kwon on 12/07/2025.
//

import SwiftUI
import Factory
import BuddyDomain

struct TaxiRoomCell: View {
  let room: TaxiRoom

  @Environment(\.taxiUser) private var taxiUser: TaxiUser?

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      VStack(alignment: .leading, spacing: 4) {
        HStack(alignment: .top) {
          Label(room.source.title.localized(), systemImage: "location.fill")

          Spacer()

          if room.isDeparted,
             let taxiUser = taxiUser {
            TaxiRoomStatusIndicator(
              settlementType: room.participants.first(where: { $0.id == taxiUser.oid })?.isSettlement ?? .notDeparted,
              settlementCount: room.settlementTotal ?? 0,
              participantsCount: room.participants.count
            )
          } else {
            TaxiParticipantsIndicator(participants: room.participants.count, capacity: room.capacity)
          }
        }
        Label(room.destination.title.localized(), systemImage: "flag.pattern.checkered")
      }
      .fontWeight(.medium)

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
    .background(Color.secondarySystemGroupedBackground, in: .rect(cornerRadius: 28))
  }
}

#Preview {
  let room: TaxiRoom = TaxiRoom.mock
  ZStack {
    Color.systemGroupedBackground
    TaxiRoomCell(room: room)
      .padding()
  }
  .ignoresSafeArea()
}
