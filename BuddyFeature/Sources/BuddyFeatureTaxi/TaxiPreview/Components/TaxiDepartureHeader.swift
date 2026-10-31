//
//  TaxiDepartureHeader.swift
//  BuddyFeature
//

import SwiftUI

/// When the ride leaves: the day and date on one line ("오늘 · 10월 26일 (월)"), the time large
/// beneath it, and a countdown beside the time once departure is under 12 hours away.
struct TaxiDepartureHeader: View {
  let date: Date

  @ScaledMetric(relativeTo: .largeTitle) private var timeSize: CGFloat = 64

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text(date.taxiDayString)
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.secondary)

      HStack(spacing: 12) {
        Text(date.formatted(date: .omitted, time: .shortened))
          .font(.system(size: timeSize, weight: .semibold))
          .monospacedDigit()
          .lineLimit(1)
          .minimumScaleFactor(0.6)

        countdown
      }
    }
    .accessibilityElement(children: .combine)
  }

  @ViewBuilder
  private var countdown: some View {
    let untilDeparture = date.timeIntervalSinceNow
    if untilDeparture > 0, untilDeparture < 12 * 60 * 60 {
      let tint: Color = untilDeparture < 60 * 60 ? .orange : .indigo
      // Not a `Label`: in a list row, as in the ride info, it shows only its icon.
      HStack(spacing: 4) {
        Image(systemName: "clock.fill")
        Text(date, format: .relative(presentation: .named, unitsStyle: .abbreviated))
      }
      .font(.footnote.weight(.semibold))
      .foregroundStyle(tint)
      .padding(.vertical, 5)
      .padding(.horizontal, 10)
      .background(tint.opacity(0.18), in: .capsule)
      .fixedSize()
    }
  }
}

extension Date {
  /// "Today · Mon, Oct 26" for today and tomorrow, otherwise just the date.
  var taxiDayString: String {
    let monthDay = formatted(.dateTime.month(.abbreviated).day().weekday(.abbreviated))
    let relative = DateFormatter()
    relative.dateStyle = .short
    relative.doesRelativeDateFormatting = true
    let plain = DateFormatter()
    plain.dateStyle = .short
    let word = relative.string(from: self)
    return word == plain.string(from: self) ? monthDay : "\(word) · \(monthDay)"
  }
}

#Preview {
  VStack(alignment: .leading, spacing: 24) {
    TaxiDepartureHeader(date: .now.addingTimeInterval(25 * 60))
    TaxiDepartureHeader(date: .now.addingTimeInterval(5 * 60 * 60))
    TaxiDepartureHeader(date: .now.addingTimeInterval(3 * 24 * 60 * 60))
  }
  .padding()
}
