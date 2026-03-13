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
  let selectedTimetable: Timetable?

  var body: some View {
    Chart([
      LectureCreditData(lectureType: .br, credits: selectedTimetable?.getCreditsFor(.br) ?? 0),
      LectureCreditData(lectureType: .be, credits: selectedTimetable?.getCreditsFor(.be) ?? 0),

      LectureCreditData(lectureType: .mr, credits: selectedTimetable?.getCreditsFor(.mr) ?? 0),
      LectureCreditData(lectureType: .me, credits: selectedTimetable?.getCreditsFor(.me) ?? 0),

      LectureCreditData(lectureType: .hse, credits: selectedTimetable?.getCreditsFor(.hse) ?? 0),
      LectureCreditData(lectureType: .etc, credits: selectedTimetable?.getCreditsFor(.etc) ?? 0)
    ]) { element in
      Plot {
        BarMark(x: .value("Credits", element.credits))
          .foregroundStyle(
            by: .value("LectureType", "\(element.lectureType.shortCode)(\(element.credits))")
          )
      }
    }
    .chartPlotStyle { plotArea in
      plotArea
        .background(Color.systemFill)
        .cornerRadius(8)
    }
    .chartXScale(domain: 0...max((selectedTimetable?.credits ?? 1), 1))
    .chartLegend(position: .bottom)
    .frame(height: 60)
  }
}

#Preview {
//  TimetableCreditGraph()
}
