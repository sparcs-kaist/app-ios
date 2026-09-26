//
//  TimetableSmallWidgetView.swift
//  BuddyUI
//
//  Created by Soongyu Kwon on 26/09/2026.
//

import SwiftUI
import BuddyDomain
import TimetableUI

/// The week at a glance for the small widget: a colour-only silhouette column per
/// day under its day letter, with today's letter highlighted.
public struct TimetableSmallWidgetView: View {
  var entry: TimetableEntry

  public init(entry: TimetableEntry) {
    self.entry = entry
  }

  public var body: some View {
    let days = entry.timetable?.visibleDays ?? DayType.weekdays
    // Set when the theme has a background (or its own label colour): the system's
    // secondary and quaternary greys would barely show over it.
    let themedLabel = entry.theme.gridLabelColor

    // One column per day, each a letter over a single-day silhouette, so the
    // letter always sits over its column. Every silhouette derives its time range
    // from the whole timetable, so the columns share one time scale.
    HStack(spacing: 4) {
      ForEach(days) { day in
        VStack(spacing: 4) {
          Text(Self.letter(for: day))
            .font(.system(size: 11, weight: day == .today ? .bold : .semibold))
            .foregroundStyle(Self.letterStyle(isToday: day == .today, themedLabel: themedLabel))

          TimetableSilhouetteView(
            timetable: entry.timetable,
            visibleDays: [day],
            trackColor: themedLabel?.opacity(0.18)
          )
        }
        .frame(maxWidth: .infinity)
      }
    }
    .timetableTheme(entry.theme)
  }

  /// Today stands out in red, or at full strength in the theme's label colour, where
  /// red could clash with the background; other days are dimmer.
  private static func letterStyle(isToday: Bool, themedLabel: Color?) -> AnyShapeStyle {
    guard let themedLabel else {
      return isToday ? AnyShapeStyle(.red) : AnyShapeStyle(.secondary)
    }
    return AnyShapeStyle(isToday ? themedLabel : themedLabel.opacity(0.6))
  }

  private static func letter(for day: DayType) -> String {
    // Calendar symbols are indexed Sun...Sat; DayType raw values are Mon...Sun.
    let symbols = Calendar.current.veryShortStandaloneWeekdaySymbols
    let index = day == .sun ? 0 : day.rawValue + 1
    return symbols[index]
  }
}
