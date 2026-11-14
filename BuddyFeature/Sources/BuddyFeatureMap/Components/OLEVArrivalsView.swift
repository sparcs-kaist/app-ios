//
//  OLEVArrivalsView.swift
//  BuddyFeatureMap
//
//  Created by Soongyu Kwon on 30/10/2026.
//

import SwiftUI
import BuddyDomain

/// The three times a stop sign would show: the bus that just left, the next one and the one after.
struct OLEVArrivalsView: View {
  let stop: CampusPlace
  let timetable: OLEVTimetable
  var style: Style = .full

  enum Style {
    /// Three tiles, for the place card.
    case full
    /// One line, for cards and rows.
    case compact
  }

  var body: some View {
    TimelineView(.periodic(from: .now, by: 15)) { context in
      let arrivals = timetable.arrivals(at: stop.id, around: context.date)
      switch style {
      case .full:
        full(arrivals, now: context.date)
      case .compact:
        compact(arrivals, now: context.date)
      }
    }
  }

  private func full(_ arrivals: OLEVArrivals, now: Date) -> some View {
    HStack(spacing: 8) {
      tile(
        title: String(localized: "Departed", bundle: .module),
        value: arrivals.previous?.formatted(date: .omitted, time: .shortened) ?? "—",
        emphasised: false
      )
      tile(
        title: String(localized: "Next", bundle: .module),
        value: arrivals.next.map { $0.olevCountdownText(now: now) } ?? "—",
        emphasised: true
      )
      tile(
        title: String(localized: "After", bundle: .module),
        value: arrivals.upcoming.dropFirst().first.map { $0.olevCountdownText(now: now) } ?? "—",
        emphasised: false
      )
    }
  }

  private func tile(title: String, value: String, emphasised: Bool) -> some View {
    VStack(spacing: 2) {
      Text(title)
        .font(.caption.weight(.medium))
        .foregroundStyle(emphasised ? .white.opacity(0.85) : .secondary)
      Text(value)
        .font(.headline.monospacedDigit())
        .foregroundStyle(emphasised ? .white : .primary)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .contentTransition(.numericText())
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 10)
    .background {
      if emphasised {
        RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.blue.gradient)
      } else {
        RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.fill.tertiary)
      }
    }
  }

  @ViewBuilder
  private func compact(_ arrivals: OLEVArrivals, now: Date) -> some View {
    if let next = arrivals.next {
      HStack(spacing: 4) {
        Image(systemName: "bus.fill")
          .foregroundStyle(.blue)
        Text("Next bus \(next.olevCountdownText(now: now))", bundle: .module)
          .fontWeight(.semibold)
          .monospacedDigit()
        if let after = arrivals.upcoming.dropFirst().first {
          Text("· then \(after.formatted(date: .omitted, time: .shortened))", bundle: .module)
            .foregroundStyle(.secondary)
        }
      }
      .lineLimit(1)
    }
  }

}

extension Date {
  /// "Now", "4 min", or a clock time once it's over an hour away (e.g. Monday's first bus).
  func olevCountdownText(now: Date = .now) -> String {
    let minutes = Int(timeIntervalSince(now) / 60)
    if minutes < 1 {
      return String(localized: "Now", bundle: .module)
    } else if minutes < 60 {
      return String(localized: "\(minutes) min", bundle: .module)
    } else if Calendar.current.isDate(self, inSameDayAs: now) {
      return formatted(date: .omitted, time: .shortened)
    } else {
      return formatted(.dateTime.weekday(.abbreviated).hour().minute())
    }
  }
}

/// The OLEV loop as a list of its stops in riding order, the way a transit app lists a line: every
/// stop named, the one being looked at marked, when the next bus reaches each, and the buses
/// running right now drawn on the line between the stops they are travelling between.
struct OLEVRouteList: View {
  let stops: [CampusPlace]
  let timetable: OLEVTimetable
  let currentStopID: String
  var onSelect: ((CampusPlace) -> Void)?

  private static var rowHeight: CGFloat { 44 }

  var body: some View {
    TimelineView(.periodic(from: .now, by: 15)) { context in
      let buses = timetable.buses(at: context.date)

      VStack(alignment: .leading, spacing: 0) {
        ForEach(Array(stops.enumerated()), id: \.element.id) { index, stop in
          let isCurrent = stop.id == currentStopID

          Button {
            onSelect?(stop)
          } label: {
            HStack(spacing: 12) {
              rail(
                isCurrent: isCurrent,
                isFirst: index == stops.startIndex,
                isLast: index == stops.index(before: stops.endIndex),
                hasBusAhead: buses.contains { $0.fromStopIndex == index }
              )

              VStack(alignment: .leading, spacing: 0) {
                Text(stop.displayName)
                  .font(.subheadline.weight(isCurrent ? .bold : .regular))
                  .lineLimit(1)
                if isCurrent {
                  Text("This stop", bundle: .module)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.blue)
                }
              }

              Spacer(minLength: 8)

              if let next = timetable.arrivals(at: stop.id, around: context.date).next {
                Text(next.olevCountdownText(now: context.date))
                  .font(.subheadline.monospacedDigit().weight(isCurrent ? .semibold : .regular))
                  .foregroundStyle(isCurrent ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary))
                  .lineLimit(1)
              }
            }
            .frame(height: Self.rowHeight)
            .contentShape(.rect)
          }
          .buttonStyle(.plain)
          // Not `disabled`, which would dim the very row that should stand out.
          .allowsHitTesting(!isCurrent && onSelect != nil)
        }
      }
    }
  }

  /// The line with this stop's dot on it, and a bus below the dot when one is on its way to the
  /// next stop.
  private func rail(isCurrent: Bool, isFirst: Bool, isLast: Bool, hasBusAhead: Bool) -> some View {
    ZStack {
      VStack(spacing: 0) {
        Rectangle().fill(isFirst ? AnyShapeStyle(.clear) : AnyShapeStyle(Color.blue.opacity(0.35)))
        Rectangle().fill(isLast ? AnyShapeStyle(.clear) : AnyShapeStyle(Color.blue.opacity(0.35)))
      }
      .frame(width: 3)

      Circle()
        .fill(isCurrent ? Color.blue : Color(uiColor: .systemBackground))
        .stroke(Color.blue, lineWidth: 2)
        .frame(width: isCurrent ? 16 : 10, height: isCurrent ? 16 : 10)
    }
    .frame(width: 24, height: Self.rowHeight)
    .overlay(alignment: .bottom) {
      if hasBusAhead {
        Image(systemName: "bus.fill")
          .font(.system(size: 9, weight: .bold))
          .foregroundStyle(.white)
          .frame(width: 20, height: 20)
          .background(Color.blue, in: .circle)
          .overlay(Circle().stroke(Color(uiColor: .systemBackground), lineWidth: 2))
          // Half a row down: on the line between this stop and the next.
          .offset(y: 10)
          .accessibilityLabel(Text("Bus on the way to the next stop", bundle: .module))
      }
    }
    .zIndex(hasBusAhead ? 1 : 0)
  }
}
