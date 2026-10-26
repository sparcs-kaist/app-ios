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
    HStack(spacing: 16) {
      // A fixed width keeps the dividers lined up down the list, whatever the locale's time and
      // date formats; longer ones ("12:40 PM", "10월 29일 (목)") shrink to fit instead.
      departure
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .frame(width: 88, alignment: .leading)

      Divider()
        .padding(.vertical, 2)

      VStack(alignment: .leading, spacing: 10) {
        TaxiRouteStops(source: room.source.title.localized(), destination: room.destination.title.localized())

        HStack {
          Text(room.title)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .lineLimit(1)

          Spacer(minLength: 8)

          if room.isDeparted,
             let taxiUser = taxiUser {
            TaxiRoomStatusIndicator(
              settlementType: room.participants.first(where: { $0.id == taxiUser.oid })?.isSettlement ?? .notDeparted,
              settlementCount: room.settlementTotal ?? 0,
              participantsCount: room.participants.count
            )
          } else {
            TaxiSeatDots(taken: room.participants.count, capacity: room.capacity)
          }
        }
      }
    }
    .fixedSize(horizontal: false, vertical: true)
    .padding(16)
    .padding(.horizontal, 4)
    .accessibilityElement(children: .combine)
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

  /// Departure time, with a countdown underneath when the ride is close and the date otherwise —
  /// the cell also appears outside the day-grouped list (My Rides, Search), where the date is
  /// the only clue to which day the time belongs to.
  private var departure: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(room.departAt.formatted(date: .omitted, time: .shortened))
        .font(.title2.weight(.semibold))
        .monospacedDigit()

      let untilDeparture = room.departAt.timeIntervalSinceNow
      if !room.isDeparted, untilDeparture > 0, untilDeparture < 12 * 60 * 60 {
        Text(room.departAt, format: .relative(presentation: .named, unitsStyle: .abbreviated))
          .font(.caption.weight(.medium))
          .foregroundStyle(untilDeparture < 60 * 60 ? .orange : .secondary)
      } else {
        Text(room.departAt, format: .dateTime.month(.abbreviated).day().weekday(.abbreviated))
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
  }
}

/// One dot per seat, filled for each rider and tinted by how many seats are left.
private struct TaxiSeatDots: View {
  let taken: Int
  let capacity: Int

  var body: some View {
    HStack(spacing: 4) {
      ForEach(0..<capacity, id: \.self) { index in
        Circle()
          .fill(index < taken ? accentColor : Color.secondary.opacity(0.25))
          .frame(width: 7, height: 7)
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(Text("\(taken)/\(capacity)", bundle: .module))
  }

  private var accentColor: Color {
    switch capacity - taken {
    case ...0:
      .red
    case 1:
      .orange
    default:
      .green
    }
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
