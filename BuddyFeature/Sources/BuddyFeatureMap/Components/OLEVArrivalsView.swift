//
//  OLEVArrivalsView.swift
//  BuddyFeatureMap
//
//  Created by Soongyu Kwon on 30/10/2026.
//

import SwiftUI
import BuddyDomain

struct OLEVArrivalsView: View {
  let stop: CampusPlace
  let timetable: OLEVTimetable
  var style: Style = .full
  var showsEdgePeeks = false

  @State private var scrollPosition = ScrollPosition(idType: Date.self)

  private static let cardSpacing: CGFloat = 8

  enum Style {
    case full
    /// One line, for cards and rows.
    case compact
  }

  var body: some View {
    TimelineView(.periodic(from: .now, by: 15)) { context in
      switch style {
      case .full:
        full(schedule(around: context.date), now: context.date)
      case .compact:
        compact(timetable.arrivals(at: stop.id, around: context.date), now: context.date)
      }
    }
  }

  private func schedule(around now: Date) -> [Date] {
    let calendar = Calendar.current
    for dayOffset in 0...7 {
      guard let day = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }
      let arrivals = timetable.scheduledArrivals(at: stop.id, on: day, calendar: calendar)
      if !arrivals.isEmpty { return arrivals }
    }
    return []
  }

  private func full(_ arrivals: [Date], now: Date) -> some View {
    let next = arrivals.first { $0 > now }

    return VStack(alignment: .leading, spacing: 8) {
      HStack(alignment: .firstTextBaseline) {
        Text("OLEV Departures", bundle: .module)
          .font(.title3.weight(.bold))
        Spacer(minLength: 8)
        if let day = arrivals.first {
          Text(day, format: .dateTime.month(.abbreviated).day().weekday(.abbreviated))
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }

      if arrivals.isEmpty {
        Text("No scheduled departures", bundle: .module)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      } else {
        ScrollView(.horizontal) {
          HStack(spacing: Self.cardSpacing) {
            ForEach(arrivals, id: \.self) { arrival in
              departureCard(at: arrival, now: now, isNext: arrival == next)
            }
          }
          .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned(limitBehavior: .alwaysByFew))
        .scrollPosition($scrollPosition, anchor: .leading)
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
        .animation(.smooth(duration: 0.25)) { content in
          content.clipShape(DepartureCarouselClip(horizontalOverflow: showsEdgePeeks ? 16 : 0))
        }
        .onChange(of: arrivals, initial: true) { _, arrivals in
          if let target = arrivals.last(where: { $0 <= now }) ?? arrivals.first {
            scrollPosition.scrollTo(id: target, anchor: .leading)
          }
        }
      }
    }
  }

  private func departureCard(at date: Date, now: Date, isNext: Bool) -> some View {
    let isPast = date <= now

    return VStack(alignment: .leading, spacing: 4) {
      Group {
        if isPast {
          Text("Departed", bundle: .module)
        } else if isNext {
          Text("Next", bundle: .module)
        } else {
          Text("Scheduled", bundle: .module)
        }
      }
      .font(.caption.weight(.semibold))
      .foregroundStyle(isNext ? Color.white.opacity(0.85) : Color.secondary)
      .lineLimit(1)
      .minimumScaleFactor(0.8)

      Text(date, format: .dateTime.hour().minute())
        .font(.headline.weight(.semibold).monospacedDigit())
        .foregroundStyle(isNext ? Color.white : isPast ? Color.secondary : Color.primary)
        .lineLimit(1)
        .minimumScaleFactor(0.8)

      Group {
        if isPast && now.timeIntervalSince(date) < 60 {
          Text("Just departed", bundle: .module)
        } else if !isPast && date.timeIntervalSince(now) < 60 {
          Text("Departing soon", bundle: .module)
        } else {
          Text(now, format: Date.AnchoredRelativeFormatStyle(
            anchor: date,
            allowedFields: [.day, .hour, .minute],
            presentation: .numeric,
            unitsStyle: .abbreviated
          ))
        }
      }
      .font(.caption.weight(.medium))
      .foregroundStyle(isNext ? Color.white.opacity(0.85) : Color.secondary)
      .lineLimit(1)
      .minimumScaleFactor(0.8)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(14)
    .containerRelativeFrame(.horizontal, count: 3, spacing: Self.cardSpacing)
    .background {
      if isNext {
        RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.blue.gradient)
      } else if isPast {
        RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.fill.quaternary)
      } else {
        RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.fill.tertiary)
      }
    }
    .accessibilityElement(children: .combine)
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

private struct DepartureCarouselClip: Shape {
  var horizontalOverflow: CGFloat

  var animatableData: CGFloat {
    get { horizontalOverflow }
    set { horizontalOverflow = newValue }
  }

  func path(in rect: CGRect) -> Path {
    RoundedRectangle(cornerRadius: max(14 - horizontalOverflow, 0), style: .continuous)
      .path(in: rect.insetBy(dx: -horizontalOverflow, dy: 0))
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
