//
//  FriendTimetableView.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 28/09/2026.
//

import SwiftUI
import BuddyDomain

/// Placeholder for viewing a friend's timetable. The backend API for this is
/// not available yet; this screen is the landing spot so it can be filled in
/// once it ships.
struct FriendTimetableView: View {
  let friend: Friend

  var body: some View {
    ContentUnavailableView {
      Label {
        Text("Timetable Coming Soon", bundle: .module)
      } icon: {
        Image(systemName: "calendar.badge.clock")
      }
    } description: {
      Text("You’ll be able to see \(friend.name)’s timetable here soon.", bundle: .module)
    }
    .navigationTitle(friend.name)
    .toolbarTitleDisplayMode(.inline)
  }
}

#Preview {
  NavigationStack {
    FriendTimetableView(friend: .mock)
  }
}
