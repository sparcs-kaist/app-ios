//
//  TimetableCreditGraph.swift
//  soap
//
//  Created by Soongyu Kwon on 20/09/2025.
//

import SwiftUI
import Charts
import BuddyDomain

struct TimetableCreditGraph: View {
  @Environment(TimetableViewModel.self) private var timetableViewModel

  var body: some View {
    Chart([
      LectureCreditData(lectureType: .br, credits: timetableViewModel.selectedTimetable?.getCreditsFor(.br) ?? 0),
      LectureCreditData(lectureType: .be, credits: timetableViewModel.selectedTimetable?.getCreditsFor(.be) ?? 0),

      LectureCreditData(lectureType: .mr, credits: timetableViewModel.selectedTimetable?.getCreditsFor(.mr) ?? 0),
      LectureCreditData(lectureType: .me, credits: timetableViewModel.selectedTimetable?.getCreditsFor(.me) ?? 0),

      LectureCreditData(lectureType: .hse, credits: timetableViewModel.selectedTimetable?.getCreditsFor(.hse) ?? 0),
      LectureCreditData(lectureType: .etc, credits: timetableViewModel.selectedTimetable?.getCreditsFor(.etc) ?? 0)
    ]) { element in
      Plot {
        BarMark(x: .value("Credits", element.credits))
          .foregroundStyle(by: .value("LectureType", element.lectureType.shortCode))
      }
    }
    .chartPlotStyle { plotArea in
      plotArea
        .background(Color.systemFill)
        .cornerRadius(8)
    }
    .chartXScale(domain: 0...max((timetableViewModel.selectedTimetable?.credits ?? 1), 1))
    .chartLegend(position: .bottom)
    .frame(height: 60)
  }
}

#Preview {
  TimetableCreditGraph()
    .environment(TimetableViewModel())
}
