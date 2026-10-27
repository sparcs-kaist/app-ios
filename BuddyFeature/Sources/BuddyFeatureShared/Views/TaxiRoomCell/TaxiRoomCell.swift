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
  /// Whether to show the riders' photos rather than one dot per seat, for rooms you are in, such
  /// as in Chats, where who you share the chat with matters more than whether seats are left.
  let showsRiders: Bool

  public init(room: TaxiRoom, withOutBackground: Bool, showsRiders: Bool = false) {
    self.room = room
    self.withOutBackground = withOutBackground
    self.showsRiders = showsRiders
  }

  @Environment(\.taxiUser) private var taxiUser: TaxiUser?
  @Environment(\.colorScheme) private var colorScheme

  /// Narrower than this — a list column beside a chat on a wide display — the time goes above
  /// the route rather than beside it, so the route and the status keep a usable width.
  private static let stackedWidth: CGFloat = 320
  @State private var isStacked = false

  public var body: some View {
    Group {
      if isStacked {
        VStack(alignment: .leading, spacing: 12) {
          stackedDeparture

          details
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      } else {
        HStack(spacing: 16) {
          // A fixed width keeps the dividers lined up down the list, whatever the locale's time and
          // date formats; longer ones ("12:40 PM", "10월 29일 (목)") shrink to fit instead.
          VStack(alignment: .leading, spacing: 2) {
            departureTime
            departureDetail
            // At the foot of the column, level with the title row beside it and as tall as the
            // riders' photos there.
            if let status {
              Spacer(minLength: 8)
              status
            }
          }
          .lineLimit(1)
          .minimumScaleFactor(0.7)
          .frame(width: 88, alignment: .leading)
          .frame(maxHeight: .infinity, alignment: status == nil ? .center : .top)

          Divider()
            .padding(.vertical, 2)

          details
        }
      }
    }
    .fixedSize(horizontal: false, vertical: true)
    .padding(16)
    .padding(.horizontal, 4)
    .onGeometryChange(for: Bool.self) { $0.size.width < Self.stackedWidth } action: { isStacked = $0 }
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

  private var details: some View {
    VStack(alignment: .leading, spacing: 10) {
      TaxiRouteStops(source: room.source.title.localized(), destination: room.destination.title.localized())

      HStack {
        Text(room.title)
          .font(.footnote)
          .foregroundStyle(.secondary)
          .lineLimit(1)

        Spacer(minLength: 8)

        if showsRiders {
          // Once the ride has left, how many seats were taken no longer matters.
          TaxiRiderStack(participants: room.participants, capacity: room.capacity, showsCount: status == nil)
            .fixedSize()
        } else if status == nil {
          TaxiSeatDots(taken: room.participants.count, capacity: room.capacity)
        }
      }
    }
  }

  /// The time line of a stacked cell. The time and date never give way: when the status does
  /// not fit beside them the date goes under the time, and only when even that is too wide does
  /// the status go on a line of its own.
  @ViewBuilder
  private var stackedDeparture: some View {
    let time = HStack(alignment: .firstTextBaseline, spacing: 8) {
      departureTime
      departureDetail
    }
    .lineLimit(1)
    .fixedSize()

    if let status {
      ViewThatFits(in: .horizontal) {
        HStack(spacing: 8) {
          time
          Spacer(minLength: 0)
          status.fixedSize()
        }
        HStack(spacing: 8) {
          VStack(alignment: .leading, spacing: 2) {
            departureTime
            departureDetail
          }
          .lineLimit(1)
          .fixedSize()
          Spacer(minLength: 0)
          status.fixedSize()
        }
        VStack(alignment: .leading, spacing: 8) {
          time
          status.fixedSize()
        }
      }
    } else {
      time
    }
  }

  /// Where your settlement stands, once the ride has left.
  private var status: TaxiRoomStatusIndicator? {
    guard room.isDeparted, let taxiUser else { return nil }
    return TaxiRoomStatusIndicator(
      settlementType: room.participants.first(where: { $0.id == taxiUser.oid })?.isSettlement ?? .notDeparted,
      settlementCount: room.settlementTotal ?? 0,
      participantsCount: room.participants.count,
      height: TaxiRiderStack.height
    )
  }

  private var departureTime: some View {
    Text(room.departAt.formatted(date: .omitted, time: .shortened))
      .font(.title2.weight(.semibold))
      .monospacedDigit()
  }

  /// Next to the departure time, a countdown when the ride is close and the date otherwise —
  /// the cell also appears outside the day-grouped list (My Rides, Search), where the date is
  /// the only clue to which day the time belongs to.
  @ViewBuilder
  private var departureDetail: some View {
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

/// Who is riding: up to four photos, overlapping, with how many are riding of how many seats.
private struct TaxiRiderStack: View {
  let participants: [TaxiParticipant]
  let capacity: Int
  var showsCount: Bool = true

  private static let photoSize: CGFloat = 22
  private static let ringWidth: CGFloat = 1.5
  /// The photos' height with their rings, which the settlement status matches.
  static let height = photoSize + ringWidth * 2
  private var photoSize: CGFloat { Self.photoSize }

  var body: some View {
    HStack(spacing: 6) {
      HStack(spacing: -photoSize * 0.3) {
        ForEach(participants.prefix(4)) { participant in
          TaxiProfilePhoto(url: participant.profileImageURL)
            .frame(width: photoSize, height: photoSize)
            // A ring of the cell's own colour keeps each photo apart from the one it overlaps.
            .padding(Self.ringWidth)
            .background(Color.secondarySystemGroupedBackground, in: .circle)
        }
      }

      if showsCount {
        Text("\(participants.count)/\(capacity)", bundle: .module)
          .font(.footnote.weight(.medium))
          .monospacedDigit()
          .foregroundStyle(.secondary)
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(Text("\(participants.count)/\(capacity)", bundle: .module))
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
