//
//  TimetableSummary.swift
//  soap
//
//  Created by Soongyu Kwon on 30/12/2024.
//

import SwiftUI
import Charts

struct TimetableSummary: View {
  @Environment(TimetableViewModel.self) private var timetableViewModel

  var body: some View {
    Group {
      content
        .transition(.opacity)
        .redacted(reason: timetableViewModel.isLoading ? .placeholder : [])
        .animation(.easeInOut(duration: 0.3), value: timetableViewModel.isLoading)
    }
  }

  private var content: some View {
    HStack {
      Spacer()
      BigSummary(label: "Credit", grade: "\(timetableViewModel.selectedTimetable?.credits ?? 0)")
      Spacer()
      BigSummary(label: "AU", grade: "\(timetableViewModel.selectedTimetable?.creditAUs ?? 0)")
      Spacer()
      BigSummary(label: "Grade", grade: timetableViewModel.selectedTimetable?.gradeLetter ?? "?")
      Spacer()
      BigSummary(label: "Load", grade: timetableViewModel.selectedTimetable?.loadLetter ?? "?")
      Spacer()
      BigSummary(label: "Speech", grade: timetableViewModel.selectedTimetable?.speechLetter ?? "?")
      Spacer()
    }
  }
}

fileprivate struct BigSummary: View {
  let label: String
  let grade: String

  var body: some View {
    VStack {
      Text(grade)
        .fontWeight(.semibold)
      Text(label)
        .font(.caption)
    }
  }
}

#Preview {
  TimetableSummary()
    .environment(TimetableViewModel())
}

