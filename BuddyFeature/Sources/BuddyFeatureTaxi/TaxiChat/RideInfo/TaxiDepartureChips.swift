//
//  TaxiDepartureChips.swift
//  BuddyFeature
//

import SwiftUI

/// When the ride leaves, as chips: the day, the time, and a countdown once departure is under 12
/// hours away. They sit on one line when they fit, and otherwise put the day on a line of its own
/// above the time and countdown.
struct TaxiDepartureChips: View {
  let date: Date

  var body: some View {
    // Redrawn every half minute, so the countdown turns orange inside the hour and goes once the
    // ride has left while the info stays open; its text counts down by itself.
    TimelineView(.periodic(from: .now, by: 30)) { context in
      ViewThatFits(in: .horizontal) {
        HStack(spacing: 8) {
          dayChip
          timeChip
          countdownChip(now: context.date)
        }
        VStack(spacing: 8) {
          dayChip
          HStack(spacing: 8) {
            timeChip
            countdownChip(now: context.date)
          }
        }
      }
    }
    .accessibilityElement(children: .combine)
  }

  private var dayChip: some View {
    chip(systemImage: "calendar", tint: .secondary) {
      Text(date.taxiDayString)
    }
  }

  private var timeChip: some View {
    chip(systemImage: "clock", tint: .primary) {
      Text(date.formatted(date: .omitted, time: .shortened))
        .monospacedDigit()
    }
  }

  @ViewBuilder
  private func countdownChip(now: Date) -> some View {
    let untilDeparture = date.timeIntervalSince(now)
    if untilDeparture > 0, untilDeparture < 12 * 60 * 60 {
      chip(systemImage: "timer", tint: untilDeparture < 60 * 60 ? .orange : .indigo) {
        Text(date, format: .relative(presentation: .named, unitsStyle: .abbreviated))
      }
    }
  }

  private func chip<Content: View>(
    systemImage: String,
    tint: some ShapeStyle,
    @ViewBuilder content: () -> Content
  ) -> some View {
    HStack(spacing: 4) {
      Image(systemName: systemImage)
      content()
    }
    .font(.subheadline.weight(.semibold))
    .foregroundStyle(tint)
    .lineLimit(1)
    .fixedSize()
    .padding(.horizontal, 10)
    .padding(.vertical, 6)
    .background(Color.secondarySystemGroupedBackground, in: .capsule)
  }
}

#Preview {
  VStack(spacing: 24) {
    TaxiDepartureChips(date: .now.addingTimeInterval(12 * 60))
    TaxiDepartureChips(date: .now.addingTimeInterval(5 * 60 * 60))
    TaxiDepartureChips(date: .now.addingTimeInterval(3 * 24 * 60 * 60))
  }
  .padding()
  .background(Color.systemGroupedBackground)
}
