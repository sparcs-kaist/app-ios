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
          .overlay {
            // Over the cell, the highlight would take its taps, so the selected room could not
            // be opened again, such as after going back to the list on an iPhone.
            RoundedRectangle(cornerRadius: 28)
              .fill(Color.secondary.opacity(selectedRoom == room ? 0.3 : 0))
              .allowsHitTesting(false)
          }
      }
    }
  }
}
