//
//  TimetableGrid.swift
//  soap
//
//  Created by Soongyu Kwon on 28/12/2024.
//

import SwiftUI
import BuddyDomain
import Haptica

struct TimetableGrid: View {
  let selectedTimetable: V2Timetable?
  let candidateLecture: V2Lecture?
  var selectedLecture: ((V2LectureItem) -> Void)?

  private let defaultMinMinutes: Int = 540       // 8:00 AM
  private let defaultMaxMinutes: Int = 1080      // 6:00 PM
  private let defaultVisibleDays: [DayType] = [.mon, .tue, .wed, .thu, .fri]

  var body: some View {
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
                    Task {
//                      await timetableViewModel.deleteLecture(lecture: item.lecture)
                    }
                  }
                )
                .frame(height: TimetableConstructor.getCellHeightV2(for: item, in: geometry.size, of: selectedTimetable.gappedDuration))
                .offset(y: TimetableConstructor.getCellOffsetV2(for: item, in: geometry.size, at: selectedTimetable.minMinutes, of: selectedTimetable.gappedDuration))
                .transition(.scale.combined(with: .opacity))
                .onTapGesture {
                  Haptic.selection.generate()
//                  selectedLecture?(item)
                }
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
      let minHour = (selectedTimetable?.minMinutes ?? defaultMinMinutes) / 60
      let maxHour = (selectedTimetable?.gappedMaxMinutes ?? defaultMaxMinutes) / 60

      ForEach(minHour..<maxHour, id: \.self) { hour in
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
      let minHour = (selectedTimetable?.minMinutes ?? defaultMinMinutes) / 60
      let maxHour = (selectedTimetable?.gappedMaxMinutes ?? defaultMaxMinutes) / 60

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

