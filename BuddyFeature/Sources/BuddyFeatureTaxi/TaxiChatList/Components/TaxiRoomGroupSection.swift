//
//  TaxiRoomGroupSection.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 13/07/2025.
//

import SwiftUI
import Factory
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

  @State private var unreadStore = Container.shared.taxiUnreadStore()

  var body: some View {
    LazyVStack(spacing: 12) {
      HStack {
        Text(title)
          .font(.title3)
          .fontWeight(.bold)

        Spacer()
      }

      ForEach(rooms) { room in
        // Rooms you are in: who you share the chat with, rather than the seats left.
        TaxiRoomCell(room: room, withOutBackground: false, showsRiders: true)
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
          .overlay(alignment: .topTrailing) {
            UnreadBadge(count: unreadStore?.counts[room.id] ?? 0)
              .offset(x: 4, y: -4)
          }
      }
    }
  }
}

/// The number of a room's unread chats on its card, or nothing when it has none.
struct UnreadBadge: View {
  let count: Int

  var body: some View {
    if count > 0 {
      Text(count > 99 ? "99+" : "\(count)")
        .font(.caption.weight(.semibold))
        .monospacedDigit()
        .foregroundStyle(.white)
        .padding(.horizontal, 7)
        .frame(minWidth: 22, minHeight: 22)
        .background(.red, in: .capsule)
        .accessibilityLabel(Text("\(count) unread", bundle: .module))
        .transition(.scale.combined(with: .opacity))
    }
  }
}
