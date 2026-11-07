//
//  TaxiRiderRow.swift
//  BuddyFeature
//

import SwiftUI
import BuddyDomain
import BuddyFeatureShared

/// Who is riding — a photo per rider, badged when they bring luggage, and a dashed circle per open
/// seat — with how many seats remain. Tapping a photo shows who that rider is.
struct TaxiRiderRow: View {
  let participants: [TaxiParticipant]
  let capacity: Int

  private let avatarSize: CGFloat = 30

  @State private var shownParticipant: TaxiParticipant.ID?

  private var seatsLeft: Int { max(capacity - participants.count, 0) }

  private var seatColor: Color {
    switch seatsLeft {
    case 0: .red
    case 1: .orange
    default: .green
    }
  }

  var body: some View {
    HStack {
      HStack(spacing: 8) {
        ForEach(participants) { participant in
          Button {
            shownParticipant = participant.id
          } label: {
            TaxiRiderAvatar(participant: participant, size: avatarSize)
          }
          .buttonStyle(.plain)
          .accessibilityLabel(participant.nickname)
          .popover(isPresented: isShown(participant)) {
            TaxiRiderCard(participant: participant)
              .presentationCompactAdaptation(.popover)
          }
        }
        ForEach(0..<seatsLeft, id: \.self) { _ in
          Circle()
            .strokeBorder(.tertiary, style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
            .frame(width: avatarSize, height: avatarSize)
            .accessibilityHidden(true)
        }
      }

      Spacer()

      Text(seatsLeft == 0 ? "Full" : "\(seatsLeft) seats left", bundle: .module)
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(seatColor)
    }
  }

  private func isShown(_ participant: TaxiParticipant) -> Binding<Bool> {
    Binding {
      shownParticipant == participant.id
    } set: { isShown in
      if !isShown, shownParticipant == participant.id {
        shownParticipant = nil
      }
    }
  }
}

/// A rider's photo, badged with a suitcase when they bring luggage unless the caller shows that
/// another way.
struct TaxiRiderAvatar: View {
  let participant: TaxiParticipant
  let size: CGFloat
  var showsLuggage: Bool = true

  /// Indigo as it is in light mode, in either appearance. Dark mode's lighter indigo left the white
  /// suitcase so faint on it that the badge looked see-through.
  private static let badgeColor = Color(
    UIColor.systemIndigo.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
  )

  var body: some View {
    TaxiProfilePhoto(url: participant.profileImageURL)
      .frame(width: size, height: size)
      .overlay(alignment: .bottomTrailing) {
        if showsLuggage, participant.hasCarrier {
          Image(systemName: "suitcase.rolling.fill")
            .font(.system(size: size * 0.3))
            .foregroundStyle(.white)
            .padding(size * 0.1)
            .background(Self.badgeColor, in: .circle)
            .offset(x: size * 0.1, y: size * 0.1)
        }
      }
  }
}

/// Who a rider is: their name, whether they verified a phone number, and whether they bring
/// luggage. Shown from a rider's photo on the ride's preview and in its chat.
struct TaxiRiderCard: View {
  let participant: TaxiParticipant

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack(spacing: 12) {
        TaxiRiderAvatar(participant: participant, size: 44)
        Text(participant.nickname)
          .font(.headline)
          .lineLimit(2)
      }

      Divider()

      VStack(alignment: .leading, spacing: 4) {
        if participant.badge {
          Label {
            Text("Phone Verified", bundle: .module)
          } icon: {
            Image(systemName: "phone.circle.fill")
              .foregroundStyle(Color.accentColor)
          }
          Text("Members with this badge can resolve issues through SPARCS mediation when problems arise.", bundle: .module)
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        } else {
          Label {
            Text("Not Verified", bundle: .module)
          } icon: {
            Image(systemName: "phone.circle")
          }
          .foregroundStyle(.secondary)
        }
      }

      if participant.hasCarrier {
        Label {
          Text("With Luggage", bundle: .module)
        } icon: {
          Image(systemName: "suitcase.rolling.fill")
            .foregroundStyle(.indigo)
        }
      } else {
        Label {
          Text("No Luggage", bundle: .module)
        } icon: {
          Image(systemName: "suitcase.rolling")
        }
        .foregroundStyle(.secondary)
      }
    }
    .font(.subheadline)
    .padding()
    .frame(width: 260, alignment: .leading)
  }
}
