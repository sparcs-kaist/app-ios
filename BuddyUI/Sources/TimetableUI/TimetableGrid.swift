//
//  TimetableGrid.swift
//  soap
//
//  Created by Soongyu Kwon on 28/12/2024.
//

import SwiftUI
import BuddyDomain
import Haptica

public struct TimetableGrid: View {
  let selectedTimetable: Timetable?
  let candidateLecture: Lecture?
  let visibleDays: [DayType]?
  let showsDayHeader: Bool
  let beginTime: Int?
  let endTime: Int?
  let selectedLecture: ((LectureItem) -> Void)?
  let onDelete: ((Lecture) -> Void)?
  let onEditActivity: ((TimetableActivity) -> Void)?
  let onDeleteActivity: ((TimetableActivity) -> Void)?
  let placement: TimetablePlacement

  /// - Parameters:
  ///   - visibleDays: Optional explicit columns. Defaults to the timetable's visible days.
  ///   - showsDayHeader: Hide when the container supplies a pinned day header.
  ///     The grid's top spacing is preserved so time coordinates stay unchanged.
  ///   - beginTime: An optional custom start of the grid, in minutes from midnight
  ///     (for example `480` for 8:00 AM). Defaults to the earliest class.
  ///   - endTime: An optional custom end of the grid, in minutes from midnight.
  ///     Defaults to the latest class.
  ///
  /// Custom times only widen the grid; classes outside of them stay visible.
  public init(
    selectedTimetable: Timetable?,
    candidateLecture: Lecture? = nil,
    visibleDays: [DayType]? = nil,
    showsDayHeader: Bool = true,
    beginTime: Int? = nil,
    endTime: Int? = nil,
    selectedLecture: ((LectureItem) -> Void)? = nil,
    onDelete: ((Lecture) -> Void)? = nil,
    onEditActivity: ((TimetableActivity) -> Void)? = nil,
    onDeleteActivity: ((TimetableActivity) -> Void)? = nil,
    placement: TimetablePlacement
  ) {
    self.selectedTimetable = selectedTimetable
    self.candidateLecture = candidateLecture
    self.visibleDays = visibleDays.flatMap { $0.isEmpty ? nil : Array(Set($0)).sorted() }
    self.showsDayHeader = showsDayHeader
    self.beginTime = beginTime
    self.endTime = endTime
    self.selectedLecture = selectedLecture
    self.onDelete = onDelete
    self.onEditActivity = onEditActivity
    self.onDeleteActivity = onDeleteActivity
    self.placement = placement
  }

  public var body: some View {
    let layout = TimetableLayout(
      classes: selectedTimetable?.lectures.flatMap(\.classes) ?? [],
      activities: selectedTimetable?.activities ?? [],
      placement: placement,
      beginTime: beginTime,
      endTime: endTime
    )
    let days = visibleDays ?? selectedTimetable?.visibleDays ?? DayType.weekdays

    GeometryReader { geometry in
      ZStack(alignment: .topLeading) {
        if showsDayHeader {
          daysColumnHeader(days: days)
        }
        timesRowHeader(layout: layout, height: geometry.size.height)
        HStack(spacing: TimetableLayout.cellSpacing) {
          ForEach(days) { day in
            dayColumn(day: day, layout: layout)
          }
        }
        .padding(.leading, TimetableLayout.contentLeading)
      }
    }
  }

  private func dayColumn(day: DayType, layout: TimetableLayout) -> some View {
    let cells = TimetableLayout.cells(for: selectedTimetable?.getLectures(day: day) ?? [])

    return GeometryReader { geometry in
      ZStack(alignment: .topLeading) {
        gridHorizontalLines(layout: layout, height: geometry.size.height)
        ForEach(selectedTimetable?.activities.filter { $0.day == day && $0.duration > 0 } ?? []) { activity in
          activityCell(activity)
            .frame(width: geometry.size.width, height: max(0,
              layout.offset(at: activity.end, height: geometry.size.height)
              - layout.offset(at: activity.begin, height: geometry.size.height) - TimetableLayout.cellSpacing))
            .offset(y: layout.offset(at: activity.begin, height: geometry.size.height))
        }
        ForEach(cells) { cell in
          TimetableGridCell(
            lectureItem: cell.item,
            isCandidate: cell.item.lecture.id == candidateLecture?.id,
            placement: placement
          )
          .frame(
            width: cell.width(in: geometry.size.width),
            height: layout.cellHeight(for: cell.item, height: geometry.size.height)
          )
          .modifier(TimetableInteractionModifier(
            item: cell.item,
            onSelect: placement == .view ? selectedLecture : nil,
            onDelete: placement == .view ? onDelete : nil
          ))
          .offset(
            x: cell.x(in: geometry.size.width),
            y: layout.offset(at: cell.item.lectureClass.begin, height: geometry.size.height)
          )
          .transition(.scale.combined(with: .opacity))
        }
      }
    }
  }

  @ViewBuilder
  private func activityCell(_ activity: TimetableActivity) -> some View {
    if placement == .view, onEditActivity != nil || onDeleteActivity != nil {
      TimetableActivityCell(activity: activity, placement: placement)
        .contextMenu {
          if let onEditActivity {
            Button(String(localized: "Edit Activity", bundle: .module), systemImage: "pencil") { onEditActivity(activity) }
          }
          if let onDeleteActivity {
            Button(String(localized: "Delete Activity", bundle: .module), systemImage: "trash", role: .destructive) { onDeleteActivity(activity) }
          }
        }
    } else {
      TimetableActivityCell(activity: activity, placement: placement)
    }
  }

  private func gridHorizontalLines(layout: TimetableLayout, height: CGFloat) -> some View {
    ZStack(alignment: .topLeading) {
      ForEach(layout.hours, id: \.self) { hour in
        HorizontalLine()
          .stroke(style: StrokeStyle(lineWidth: 1))
          .frame(height: 1)
          .offset(y: layout.offset(at: hour * 60, height: height))
        HorizontalLine()
          .stroke(style: StrokeStyle(lineWidth: 1, dash: [2]))
          .frame(height: 1)
          .offset(y: layout.offset(at: hour * 60 + 30, height: height))
      }
    }
    .foregroundStyle(Color(uiColor: .separator))
    .allowsHitTesting(false)
    .accessibilityHidden(true)
  }

  private func daysColumnHeader(days: [DayType]) -> some View {
    HStack(spacing: TimetableLayout.cellSpacing) {
      ForEach(days) { day in
        Text(day.stringValue)
          .font(.caption)
          .frame(maxWidth: .infinity)
          .frame(height: TimetableLayout.daysHeight)
          .textCase(.uppercase)
          .fontDesign(.rounded)
          .fontWeight(.medium)
      }
    }
    .padding(.leading, TimetableLayout.contentLeading)
  }

  private func timesRowHeader(layout: TimetableLayout, height: CGFloat) -> some View {
    let skipAlternate = placement == .widget && layout.hours.count > 8

    return ZStack(alignment: .topLeading) {
      ForEach(layout.hours, id: \.self) { hour in
        if !skipAlternate || (hour - layout.hours.lowerBound).isMultiple(of: 2) {
          Text(String(hour))
            .font(.caption)
            .frame(width: TimetableLayout.hoursWidth)
            .fontDesign(.rounded)
            .offset(y: layout.offset(at: hour * 60, height: height) - 6)
        }
      }
    }
  }
}

/// Interaction belongs to the app grid; widget cells remain display-only.
private struct TimetableInteractionModifier: ViewModifier {
  let item: LectureItem
  let onSelect: ((LectureItem) -> Void)?
  let onDelete: ((Lecture) -> Void)?

  func body(content: Content) -> some View {
    if let onDelete {
      selectable(content)
        .contextMenu {
          Button(String(localized: "Remove from Table", bundle: .module), systemImage: "trash", role: .destructive) {
            onDelete(item.lecture)
          }
        }
    } else {
      selectable(content)
    }
  }

  @ViewBuilder
  private func selectable(_ content: Content) -> some View {
    if let onSelect {
      content
        .contentShape(.rect)
        .onTapGesture {
          Haptic.selection.generate()
          onSelect(item)
        }
        .accessibilityAddTraits(.isButton)
    } else {
      content
    }
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
