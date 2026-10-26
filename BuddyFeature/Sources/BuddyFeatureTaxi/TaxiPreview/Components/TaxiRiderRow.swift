//
//  TaxiRiderRow.swift
//  BuddyFeature
//

import SwiftUI
import NukeUI
import BuddyDomain

/// Who is riding — a photo per rider, badged when they bring luggage, and a dashed circle per open
/// seat — with how many seats remain.
struct TaxiRiderRow: View {
  let participants: [TaxiParticipant]
  let capacity: Int

  private let avatarSize: CGFloat = 30

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
          avatar(of: participant)
        }
        ForEach(0..<seatsLeft, id: \.self) { _ in
          Circle()
            .strokeBorder(.tertiary, style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
            .frame(width: avatarSize, height: avatarSize)
        }
      }
      .accessibilityHidden(true)

      Spacer()

      Text(seatsLeft == 0 ? "Full" : "\(seatsLeft) seats left", bundle: .module)
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(seatColor)
    }
  }

  private func avatar(of participant: TaxiParticipant) -> some View {
    LazyImage(url: participant.profileImageURL) { state in
      if let image = state.image {
        image
          .resizable()
          .aspectRatio(contentMode: .fill)
      } else {
        Circle()
          .fill(Color.secondarySystemFill)
      }
    }
    .frame(width: avatarSize, height: avatarSize)
    .clipShape(.circle)
    .overlay(alignment: .bottomTrailing) {
      if participant.hasCarrier {
        Image(systemName: "suitcase.rolling.fill")
          .font(.system(size: avatarSize * 0.3))
          .foregroundStyle(.white)
          .padding(3)
          .background(.indigo, in: .circle)
          .offset(x: 3, y: 3)
      }
    }
  }
}
