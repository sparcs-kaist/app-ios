//
//  TaxiRoomCell.swift
//  soap
//
//  Created by Soongyu Kwon on 12/07/2025.
//

import SwiftUI
import Factory
import BuddyDomain

public struct TaxiRoomCell: View {
  let room: TaxiRoom
  let withOutBackground: Bool

  public init(room: TaxiRoom, withOutBackground: Bool) {
    self.room = room
    self.withOutBackground = withOutBackground
  }

  @Environment(\.taxiUser) private var taxiUser: TaxiUser?
  @Environment(\.colorScheme) private var colorScheme

  public var body: some View {
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
      .fixedSize(horizontal: false, vertical: true)
      .font(.footnote)
      .foregroundStyle(.secondary)
    }
    .padding()
    .contentShape(.rect(cornerRadius: 28))
    .background(
      colorScheme == .light ? Color.secondarySystemGroupedBackground : .clear,
      in: .rect(cornerRadius: 28)
    )
    // iOS 26.1 has an issue with .identity.interactive(); temporarily disabled. See https://www.reddit.com/r/SwiftUI/comments/1osex0x/interactive_glasseffect_bug_flickering_on_ios_261/
    .glassEffect(
      colorScheme == .light || withOutBackground ? .identity : .regular.interactive(),
      in: .rect(cornerRadius: 28)
    )
  }
}

#Preview {
  let room: TaxiRoom = TaxiRoom.mock
  ZStack {
    Color.systemGroupedBackground
    TaxiRoomCell(room: room, withOutBackground: false)
      .padding()
  }
  .ignoresSafeArea()
}
