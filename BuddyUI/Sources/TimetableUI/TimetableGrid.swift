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
  var selectedLecture: ((LectureItem) -> Void)?
  var onDelete: (Lecture) -> Void
  let placement: TimetablePlacement

  public init(
    selectedTimetable: Timetable?,
    candidateLecture: Lecture?,
    selectedLecture: ((LectureItem) -> Void)? = nil,
    onDelete: @escaping (Lecture) -> Void,
    placement: TimetablePlacement
  ) {
    self.selectedTimetable = selectedTimetable
    self.candidateLecture = candidateLecture
    self.selectedLecture = selectedLecture
    self.onDelete = onDelete
    self.placement = placement
  }

  private let defaultMinMinutes: Int = 540       // 8:00 AM
  private let defaultMaxMinutes: Int = 1080      // 6:00 PM
  private let defaultVisibleDays: [DayType] = [.mon, .tue, .wed, .thu, .fri]

  public var body: some View {
    GeometryReader { geometry in
      daysColumnHeader
      timesRowHeader
      HStack(spacing: 4) {
        ForEach(selectedTimetable?.visibleDays ?? defaultVisibleDays) { day in
          ZStack(alignment: .top) {
            gridHorizontalLine
              .foregroundStyle(.separator)
            if let selectedTimetable = selectedTimetable {
              ForEach(selectedTimetable.getLectures(day: day)) { item in
                TimetableGridCell(
                  lectureItem: item,
                  isCandidate: item.lecture.id == candidateLecture?.id,
                  onDeletion: {
                    onDelete(item.lecture)
                  },
                  placement: placement
                )
                .frame(height: getHeight(for: item, in: geometry.size, of: selectedTimetable))
                .offset(y: getOffset(for: item, in: geometry.size, of: selectedTimetable))
                .transition(.scale.combined(with: .opacity))
                .onTapGesture {
                  Haptic.selection.generate()
                  selectedLecture?(item)
                }
              }
            }
          }
        }
      }
      .padding(.leading, TimetableConstructor.hoursWidth + 8)
    }
  }

  private func getHeight(for item: LectureItem, in size: CGSize, of selectedTimetable: Timetable) -> CGFloat {
    switch placement {
    case .widget:
      TimetableConstructor
        .getCellHeight(
          for: item,
          in: size,
          of: (maxHour - minHour) * 60
        )
    default:
      TimetableConstructor.getCellHeight(for: item, in: size, of: selectedTimetable.gappedDuration)
    }
  }

  private func getOffset(for item: LectureItem, in size: CGSize, of selectedTimetable: Timetable) -> CGFloat {
    switch placement {
    case .widget:
      TimetableConstructor
        .getCellOffset(
          for: item,
          in: size,
          at: selectedTimetable.minMinutes,
          of: (maxHour - minHour) * 60
        )
    default:
      TimetableConstructor.getCellOffset(for: item, in: size, at: selectedTimetable.minMinutes, of: selectedTimetable.gappedDuration)
    }
  }

  private var minHour: Int {
    (selectedTimetable?.minMinutes ?? defaultMinMinutes) / 60
  }

  private var maxHour: Int {
    var maxHour = (selectedTimetable?.gappedMaxMinutes ?? defaultMaxMinutes) / 60

    if placement == .widget {
      maxHour = (selectedTimetable?.maxMinutes ?? defaultMaxMinutes) % 60 == 0 ? maxHour : maxHour + 1
    }

    return maxHour
  }

  private var gridHorizontalLine: some View {
    VStack(spacing: 0) {
      ForEach(minHour..<maxHour, id: \.self) { hour in
        HorizontalLine()
          .stroke(style: StrokeStyle(lineWidth: 1))
        HorizontalLine()
          .stroke(style: StrokeStyle(lineWidth: 1, dash: [2]))
      }
    }
    .padding(.top, TimetableConstructor.daysHeight + 14)
  }

  private var daysColumnHeader: some View {
    HStack(spacing: 0) {
      ForEach(selectedTimetable?.visibleDays ?? defaultVisibleDays) { day in
        Text(day.stringValue)
          .font(.caption)
          .frame(maxWidth: .infinity)
          .frame(height: TimetableConstructor.daysHeight)
          .textCase(.uppercase)
          .fontDesign(.rounded)
          .fontWeight(.medium)
      }
    }.padding(.leading, TimetableConstructor.hoursWidth + 8)
  }

  private var timesRowHeader: some View {
    VStack(spacing: 0) {
      ForEach(minHour..<maxHour, id: \.self) { hour in
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

//#Preview(traits: .fixedLayout(width: 402, height: 503)) {
//  TimetableGrid()
//    .environment(TimetableViewModel())
//}

