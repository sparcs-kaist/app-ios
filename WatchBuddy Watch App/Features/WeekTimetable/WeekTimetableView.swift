//
//  WeekTimetableView.swift
//  WatchBuddy Watch App
//
//  Created by Soongyu Kwon on 24/09/2026.
//

import SwiftUI
import BuddyDomain
import TimetableUI

/// The whole week at a glance: a silhouette column per day under a pinned row
/// of day letters, with a time ruler every three hours on the left. The grid
/// scrolls vertically while the day letters stay put. Tapping a day column
/// hands the day back so the root can switch to the Day view.
struct WeekTimetableView: View {
  let timetable: Timetable
  let onSelectDay: (DayType) -> Void

  private static let gutterWidth: CGFloat = 12
  private static let headerHeight: CGFloat = 14
  private static let hourHeight: CGFloat = 32
  private static let labelHeight: CGFloat = 10

  // Shared hour-aligned bounds so every column and the ruler use one time
  // scale, always covering at least the 09:00–18:00 working day. Classes
  // outside that window only widen the grid, matching TimetableLayout.
  private var startMinutes: Int { min(540, timetable.minMinutes) }

  private var endMinutes: Int {
    max(1080, (timetable.maxMinutes + 59) / 60 * 60)
  }

  var body: some View {
    let days = timetable.visibleDays
    let gridHeight = CGFloat(endMinutes - startMinutes) / 60 * Self.hourHeight

    VStack(spacing: 2) {
      // Pinned day letters, laid out with the same structure as the grid row
      // below so each letter sits exactly over its column.
      HStack(spacing: 4) {
        Color.clear
          .frame(width: Self.gutterWidth, height: Self.headerHeight)
        ForEach(days) { day in
          Text(letter(for: day))
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(day == .today ? AnyShapeStyle(.red) : AnyShapeStyle(.secondary))
            .frame(maxWidth: .infinity)
            .frame(height: Self.headerHeight)
        }
      }

      ScrollView {
        HStack(alignment: .top, spacing: 4) {
          timeGutter
            .frame(width: Self.gutterWidth, height: gridHeight)

          ForEach(days) { day in
            Button {
              onSelectDay(day)
            } label: {
              TimetableSilhouetteView(
                timetable: timetable,
                visibleDays: [day],
                beginTime: startMinutes,
                endTime: endMinutes
              )
              .frame(maxWidth: .infinity)
              .frame(height: gridHeight)
            }
            .buttonStyle(.plain)
          }
        }
        .padding(.bottom, 8)
      }
    }
    .padding(.horizontal, 4)
    .navigationTitle("Week")
  }

  private var timeGutter: some View {
    GeometryReader { geometry in
      ForEach(threeHourMarks, id: \.self) { hour in
        Text("\(hour)")
          .font(.system(size: 9))
          .foregroundStyle(.secondary)
          .frame(width: Self.gutterWidth, alignment: .trailing)
          .offset(y: labelOffset(forHour: hour, height: geometry.size.height))
      }
    }
  }

  private var threeHourMarks: [Int] {
    let first = (startMinutes / 60 + 2) / 3 * 3
    let last = endMinutes / 60
    guard first <= last else { return [] }
    return Array(stride(from: first, through: last, by: 3))
  }

  private func labelOffset(forHour hour: Int, height: CGFloat) -> CGFloat {
    let position = height * CGFloat(hour * 60 - startMinutes) / CGFloat(endMinutes - startMinutes)
    return min(max(0, position - Self.labelHeight / 2), height - Self.labelHeight)
  }

  private func letter(for day: DayType) -> String {
    // Calendar symbols are indexed Sun...Sat; DayType raw values are Mon...Sun.
    let symbols = Calendar.current.veryShortStandaloneWeekdaySymbols
    let index = day == .sun ? 0 : day.rawValue + 1
    return symbols[index]
  }
}

#Preview {
  NavigationStack {
    WeekTimetableView(timetable: .mockList[0]) { _ in }
  }
}
