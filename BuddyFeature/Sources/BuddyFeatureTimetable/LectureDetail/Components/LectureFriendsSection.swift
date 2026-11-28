//
//  LectureFriendsSection.swift
//  BuddyFeature
//

import SwiftUI
import BuddyDomain

/// The "Friends" section of a lecture detail: friends taking this class, and friends
/// who took the course in another semester. Each opens that friend's timetable there.
struct LectureFriendsSection: View {
  let friends: LectureFriends

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Friends", bundle: .module)
        .font(.title3)
        .fontWeight(.bold)

      if !friends.sameLecture.isEmpty {
        group(String(localized: "Taking This Class", bundle: .module), entries: friends.sameLecture, showsTerm: false)
      }
      if !friends.sameCourse.isEmpty {
        group(String(localized: "Took This Course", bundle: .module), entries: friends.sameCourse, showsTerm: true)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private func group(_ title: String, entries: [LectureFriends.Entry], showsTerm: Bool) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .font(.subheadline)
        .foregroundStyle(.secondary)

      ScrollView(.horizontal) {
        HStack(spacing: 8) {
          ForEach(entries) { entry in
            NavigationLink {
              FriendTimetableView(friend: entry.friend, term: entry.term)
            } label: {
              FriendChip(name: entry.friend.name, term: showsTerm ? entry.term.description : nil)
            }
            .buttonStyle(FriendChipButtonStyle())
          }
        }
      }
      .scrollIndicators(.hidden)
      .scrollClipDisabled()
    }
  }
}

/// A capsule concentric with the avatar it holds: the avatar sits the same `inset` from
/// the top, bottom and leading edge, so the capsule's end is the avatar's circle grown by it.
private struct FriendChip: View {
  let name: String
  /// The semester they took it in, for friends from another semester.
  let term: String?

  static let avatarDiameter: CGFloat = 36
  static let inset: CGFloat = 4

  var body: some View {
    HStack(spacing: 8) {
      InitialsCircle(name: name, diameter: Self.avatarDiameter)

      VStack(alignment: .leading, spacing: 0) {
        Text(name)
          .font(.subheadline)
          .fontWeight(.medium)
          .lineLimit(1)
        if let term {
          Text(term)
            .font(.caption2)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
      }
    }
    // Fixed, so two lines of text can't grow the capsule past the avatar.
    .frame(height: Self.avatarDiameter)
    .padding(Self.inset)
    .padding(.trailing, 12)
    .glassEffect(.regular, in: .capsule)
    .contentShape(.capsule)
    .accessibilityElement(children: .combine)
    .accessibilityHint(Text("Shows their timetable", bundle: .module))
  }
}

/// Presses the chip in. Its glass isn't interactive, which would take the link's tap.
private struct FriendChipButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .foregroundStyle(.primary)
      .scaleEffect(configuration.isPressed ? 0.95 : 1)
      .animation(.spring(duration: 0.2), value: configuration.isPressed)
  }
}
