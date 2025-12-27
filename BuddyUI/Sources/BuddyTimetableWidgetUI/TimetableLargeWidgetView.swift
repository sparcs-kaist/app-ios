//
//  TimetableLargeWidgetView.swift
//  BuddyUI
//
//  Created by Soongyu Kwon on 27/12/2025.
//

import SwiftUI
import BuddyDomain
import BuddyDataCore

struct TimetableGridCell: View {
  @Environment(\.widgetRenderingMode) var renderingMode

  let lecture: Lecture
  let isCandidate: Bool
  let onDeletion: (() -> Void)?

  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .topLeading) {
        RoundedRectangle(cornerRadius: 4)
          .foregroundStyle(colorScheme == .light ? backgroundColor : backgroundColor.darkTransformedHSB())
          .widgetAccentable()
          .opacity(renderingMode == .accented ? 0.2 : 1)

        VStack(alignment: .leading, spacing: 2) {
          Text(lecture.title.localized())
            .minimumScaleFactor(0.8)
            .font(.caption)
            .lineLimit(3)

          if geometry.size.height > 40 {
            Text(lecture.classTimes[0].classroomNameShort.localized())
              .minimumScaleFactor(0.8)
              .lineLimit(2)
              .font(.caption2)
              .opacity(0.8)
          }
        }
        .foregroundStyle(lecture.textColor)
        .padding(6)
      }
    }
  }

  var backgroundColor: Color {
    lecture.backgroundColor
  }
}

public struct TimetableLargeWidgetView: View {
  var entry: TimetableEntry

  public init(entry: TimetableEntry) {
    self.entry = entry
  }

  private let defaultMinMinutes: Int = 540       // 8:00 AM
  private let defaultMaxMinutes: Int = 1080      // 6:00 PM
  private let defaultVisibleDays: [DayType] = [.mon, .tue, .wed, .thu, .fri]

  public var body: some View {
    GeometryReader { geometry in
      daysColumnHeader
      timesRowHeader
      HStack(spacing: 4) {
        ForEach(entry.timetable?.visibleDays ?? defaultVisibleDays) { day in
          ZStack(alignment: .top) {
            gridHorizontalLine
              .foregroundStyle(.secondary)
            if let timetable = entry.timetable {
              ForEach(timetable.getLectures(day: day)) { item in
                TimetableGridCell(
                  lecture: item.lecture,
                  isCandidate: false,
                  onDeletion: nil
                )
                .frame(
                  height: TimetableConstructor
                    .getCellHeight(for: item, in: geometry.size, of: timetable.duration-60)
                )
                .offset(
                  y: TimetableConstructor
                    .getCellOffset(
                      for: item,
                      in: geometry.size,
                      at: timetable.minMinutes,
                      of: timetable.duration-60
                    )
                )
              }
            }
          }
        }
      }
      .padding(.leading, TimetableConstructor.hoursWidth + 8)
    }
  }

  private var gridHorizontalLine: some View {
    VStack(spacing: 0) {
      let minHour = (entry.timetable?.minMinutes ?? defaultMinMinutes) / 60
      let maxHour = (entry.timetable?.maxMinutes ?? defaultMaxMinutes) / 60

      ForEach(minHour..<maxHour-1, id: \.self) { hour in
        HorizontalLine()
          .stroke(style: StrokeStyle(lineWidth: 1))
        HorizontalLine()
          .stroke(style: StrokeStyle(lineWidth: 1, dash: [2]))
      }.padding(.top, 10)

      Spacer()
        .frame(height: 10)
    }
    .padding(.top, TimetableConstructor.daysHeight + 4)
  }

  private var daysColumnHeader: some View {
    HStack(spacing: 0) {
      ForEach(entry.timetable?.visibleDays ?? defaultVisibleDays) { day in
        Text(day.stringValue)
          .font(.caption)
          .frame(maxWidth: .infinity)
          .frame(height: TimetableConstructor.daysHeight)
          .textCase(.uppercase)
          .fontDesign(.rounded)
          .fontWeight(.medium)
      }
    }
    .padding(.leading, TimetableConstructor.hoursWidth + 8)
  }

  private var timesRowHeader: some View {
    VStack(spacing: 0) {
      let minHour = (entry.timetable?.minMinutes ?? defaultMinMinutes) / 60
      let maxHour = (entry.timetable?.maxMinutes ?? defaultMaxMinutes) / 60

      ForEach(minHour..<maxHour-1, id: \.self) { hour in
        Text(String(hour))
          .font(.caption)
          .frame(width: TimetableConstructor.hoursWidth)
          .fontDesign(.rounded)

        Spacer()
      }

      Spacer()
        .frame(height: 6)
    }.padding(.top, TimetableConstructor.daysHeight + 8)
  }
}

private struct HorizontalLine: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: 0, y: 0))
    path.addLine(to: CGPoint(x: rect.width, y: 0))
    return path
  }
}
