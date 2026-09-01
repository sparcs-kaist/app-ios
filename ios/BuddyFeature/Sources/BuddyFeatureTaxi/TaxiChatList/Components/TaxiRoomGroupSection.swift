//
//  TaxiRoomGroupSection.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 13/07/2025.
//

import SwiftUI
import BuddyDomain
import BuddyFeatureShared

/// A titled group of taxi rooms (e.g. "Active Groups" / "Past Groups") with
/// tap-to-select and a selection highlight.
struct TaxiRoomGroupSection: View {
  let title: String
  let rooms: [TaxiRoom]
  let selectedRoom: TaxiRoom?
  let taxiUser: TaxiUser?
  let onSelect: (TaxiRoom) -> Void

  var body: some View {
    LazyVStack(spacing: 12) {
      HStack {
        Text(title)
          .font(.title3)
          .fontWeight(.bold)

        Spacer()
      }

      ForEach(rooms) { room in
        TaxiRoomCell(room: room, withOutBackground: false)
          .environment(\.taxiUser, taxiUser)
          .onTapGesture {
            onSelect(room)
          }
          .overlay(
            Color.secondary.opacity(selectedRoom == room ? 0.3 : 0),
            in: .rect(cornerRadius: 28)
          )
      }
    }
  }
}
