//
//  TimetableGrid.swift
//  soap
//
//  Created by Soongyu Kwon on 28/12/2024.
//

import SwiftUI
import BuddyDomain
import BuddyDataCore

struct TimetableGrid: View {
  @Environment(TimetableViewModel.self) private var timetableViewModel
  var selectedLecture: ((Lecture) -> Void)?

  private let defaultMinMinutes: Int = 540       // 8:00 AM
  private let defaultMaxMinutes: Int = 1080      // 6:00 PM
  private let defaultVisibleDays: [DayType] = [.mon, .tue, .wed, .thu, .fri]

  var body: some View {
    GeometryReader { geometry in
      daysColumnHeader
      timesRowHeader
      HStack(spacing: 4) {
        ForEach(timetableViewModel.selectedTimetable?.visibleDays ?? defaultVisibleDays) { day in
          ZStack(alignment: .top) {
            girdHorizontalLine
              .foregroundStyle(.separator)
            if let selectedTimetable = timetableViewModel.selectedTimetable {
              ForEach(selectedTimetable.getLectures(day: day)) { item in
                TimetableGridCell(
                  lecture: item.lecture,
                  isCandidate: item.lecture.id == timetableViewModel.candidateLecture?.id,
                  onDeletion: {
                    Task {
                      do {
                        try await timetableViewModel.deleteLecture(lecture: item.lecture)
                      } catch {
                        // TODO: Handle error
                      }
                    }
                  }
                )
                .frame(height: TimetableConstructor.getCellHeight(for: item, in: geometry.size, of: selectedTimetable.duration))
                .offset(y: TimetableConstructor.getCellOffset(for: item, in: geometry.size, at: selectedTimetable.minMinutes, of: selectedTimetable.duration))
                .animation(.easeInOut(duration: 0.3), value: timetableViewModel.isLoading)
                .onTapGesture {
                  selectedLecture?(item.lecture)
                }
              }
            }
          }
        }
      }
      .padding(.leading, TimetableConstructor.hoursWidth + 8)
    }
  }

  private var girdHorizontalLine: some View {
    VStack(spacing: 0) {
      let minHour = (timetableViewModel.selectedTimetable?.minMinutes ?? defaultMinMinutes) / 60
      let maxHour = (timetableViewModel.selectedTimetable?.maxMinutes ?? defaultMaxMinutes) / 60

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
      ForEach(timetableViewModel.selectedTimetable?.visibleDays ?? defaultVisibleDays) { day in
        Text(day.stringValue)
          .font(.caption)
          .frame(maxWidth: .infinity)
          .frame(height: TimetableConstructor.daysHeight)
      }
    }.padding(.leading, TimetableConstructor.hoursWidth + 8)
  }

  private var timesRowHeader: some View {
    VStack(spacing: 0) {
      let minHour = (timetableViewModel.selectedTimetable?.minMinutes ?? defaultMinMinutes) / 60
      let maxHour = (timetableViewModel.selectedTimetable?.maxMinutes ?? defaultMaxMinutes) / 60

      ForEach(minHour..<maxHour, id: \.self) { hour in
        Text(String(hour))
          .font(.caption)
          .frame(width: TimetableConstructor.hoursWidth)
        Spacer()
      }

      Spacer()
        .frame(height: 6)
    }.padding(.top, TimetableConstructor.daysHeight + 8)
  }
}

struct HorizontalLine: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: 0, y: 0))
    path.addLine(to: CGPoint(x: rect.width, y: 0))
    return path
  }
}

#Preview(traits: .fixedLayout(width: 402, height: 503)) {
  TimetableGrid()
    .environment(TimetableViewModel())
}

