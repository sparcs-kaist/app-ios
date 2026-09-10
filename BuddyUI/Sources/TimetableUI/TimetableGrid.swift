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
  let selectedLecture: ((LectureItem) -> Void)?
  let onDelete: ((Lecture) -> Void)?
  let placement: TimetablePlacement

  public init(
    selectedTimetable: Timetable?,
    candidateLecture: Lecture? = nil,
    selectedLecture: ((LectureItem) -> Void)? = nil,
    onDelete: ((Lecture) -> Void)? = nil,
    placement: TimetablePlacement
  ) {
    self.selectedTimetable = selectedTimetable
    self.candidateLecture = candidateLecture
    self.selectedLecture = selectedLecture
    self.onDelete = onDelete
    self.placement = placement
  }

  public var body: some View {
    let layout = TimetableLayout(
      classes: selectedTimetable?.lectures.flatMap(\.classes) ?? [],
      placement: placement
    )
    let days = selectedTimetable?.visibleDays ?? DayType.weekdays

    GeometryReader { geometry in
      ZStack(alignment: .topLeading) {
        daysColumnHeader(days: days)
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

