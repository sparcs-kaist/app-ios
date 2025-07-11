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
          Label(room.from.title.localized(), systemImage: "location.fill")
          Label(room.to.title.localized(), systemImage: "flag.pattern.checkered")
        }
        .fontWeight(.medium)

        Spacer()

        HStack(spacing: 4) {
          Text("\(room.participants.count)/\(room.capacity)")
          Image(systemName: "person.2")
        }
        .font(.footnote)
        .foregroundStyle(.green)
        .padding(4)
        .background(.green.opacity(0.1))
        .clipShape(.rect(cornerRadius: 4))
      }

      Text(room.departAt.relativeTimeString + "\t" + room.title)
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
