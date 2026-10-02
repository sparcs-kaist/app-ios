//
//  TimetableSilhouetteView.swift
//  BuddyUI
//
//  Created by Soongyu Kwon on 24/09/2026.
//

import SwiftUI
import BuddyDomain

/// A colour-only rendering of a timetable: every class and activity becomes a
/// plain rounded block on its day column, without titles, locations, or time
/// labels. Designed for tiny surfaces like the watch, where the shape and
/// colours of the week read at a glance but text would not.
public struct TimetableSilhouetteView: View {
  // Tighter than the grid's cellSpacing: with no text to separate, back-to-back
  // classes only need a hairline gap on small surfaces.
  private static let blockSpacing: CGFloat = 2

  let timetable: Timetable?
  let visibleDays: [DayType]?
  let beginTime: Int?
  let endTime: Int?
  let trackColor: Color?

  @Environment(\.timetableTheme) private var theme

  /// - Parameters:
  ///   - visibleDays: Optional explicit columns. Defaults to the timetable's visible days.
  ///   - beginTime: An optional custom start of the grid, in minutes from midnight
  ///     (for example `480` for 8:00 AM). Defaults to the earliest class.
  ///   - endTime: An optional custom end of the grid, in minutes from midnight.
  ///     Defaults to the latest class.
  ///
  ///   - trackColor: The empty day column's fill. Nil uses the system's quaternary
  ///     fill; pass a colour that reads over a themed background, e.g. in widgets.
  ///
  /// Custom times only widen the grid, matching `TimetableGrid`.
  public init(
    timetable: Timetable?,
    visibleDays: [DayType]? = nil,
    beginTime: Int? = nil,
    endTime: Int? = nil,
    trackColor: Color? = nil
  ) {
    self.timetable = timetable
    self.visibleDays = visibleDays.flatMap { $0.isEmpty ? nil : Array(Set($0)).sorted() }
    self.beginTime = beginTime
    self.endTime = endTime
    self.trackColor = trackColor
  }

  public var body: some View {
    let layout = TimetableLayout(
      classes: timetable?.lectures.flatMap(\.classes) ?? [],
      activities: timetable?.activities ?? [],
      placement: .widget,
      beginTime: beginTime,
      endTime: endTime
    )
    let days = visibleDays ?? timetable?.visibleDays ?? DayType.weekdays

    HStack(spacing: TimetableLayout.cellSpacing) {
      ForEach(days) { day in
        dayColumn(day: day, layout: layout)
      }
    }
    .accessibilityHidden(true)
  }

  private func dayColumn(day: DayType, layout: TimetableLayout) -> some View {
    let cells = TimetableLayout.cells(for: timetable?.getLectures(day: day) ?? [])
    let activities = timetable?.activities.filter { $0.day == day && $0.duration > 0 } ?? []

    return ZStack(alignment: .topLeading) {
      RoundedRectangle(cornerRadius: 4)
        .fill(trackColor.map(AnyShapeStyle.init) ?? AnyShapeStyle(.quaternary))
      GeometryReader { geometry in
        ForEach(activities) { activity in
          block(color: theme.color(forActivityID: activity.id))
            .frame(
              width: geometry.size.width,
              height: blockHeight(forDuration: activity.duration, layout: layout, height: geometry.size.height)
            )
            .offset(y: offset(at: activity.begin, layout: layout, height: geometry.size.height))
        }
        ForEach(cells) { cell in
          block(color: theme.color(forCourseID: cell.item.lecture.courseID))
            .frame(
              width: cell.width(in: geometry.size.width),
              height: blockHeight(forDuration: cell.item.lectureClass.duration, layout: layout, height: geometry.size.height)
            )
            .offset(
              x: cell.x(in: geometry.size.width),
              y: offset(at: cell.item.lectureClass.begin, layout: layout, height: geometry.size.height)
            )
        }
      }
    }
  }

  private func block(color: Color) -> some View {
    RoundedRectangle(cornerRadius: 4)
      .fill(color)
  }

  // No headers or insets: the layout's start time sits at the very top, so the
  // silhouette maps time to the full height it is given.
  private func offset(at minutes: Int, layout: TimetableLayout, height: CGFloat) -> CGFloat {
    height * CGFloat(minutes - layout.startMinutes) / CGFloat(layout.endMinutes - layout.startMinutes)
  }

  private func blockHeight(forDuration duration: Int, layout: TimetableLayout, height: CGFloat) -> CGFloat {
    max(0, height * CGFloat(duration) / CGFloat(layout.endMinutes - layout.startMinutes) - Self.blockSpacing)
  }
}

#Preview("Watch", traits: .fixedLayout(width: 170, height: 150)) {
  TimetableSilhouetteView(timetable: .mockList[0])
    .padding(8)
    .background(.black)
    .preferredColorScheme(.dark)
}

#Preview("Custom time range", traits: .fixedLayout(width: 170, height: 150)) {
  TimetableSilhouetteView(timetable: .mockList[0], beginTime: 480, endTime: 1320)
    .padding(8)
    .background(.black)
    .preferredColorScheme(.dark)
}

#Preview("Light", traits: .fixedLayout(width: 250, height: 220)) {
  TimetableSilhouetteView(timetable: .mockList[0])
    .padding(8)
}

#Preview("Empty", traits: .fixedLayout(width: 170, height: 150)) {
  TimetableSilhouetteView(timetable: nil)
    .padding(8)
    .background(.black)
    .preferredColorScheme(.dark)
}
