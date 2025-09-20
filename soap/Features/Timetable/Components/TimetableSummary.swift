//
//  TimetableSummary.swift
//  soap
//
//  Created by Soongyu Kwon on 30/12/2024.
//

import SwiftUI

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
      VStack(alignment: .leading) {
        SmallSummary(type: "BR", count: timetableViewModel.selectedTimetable?.getCreditsFor(.br) ?? 0)
        SmallSummary(type: "BE", count: timetableViewModel.selectedTimetable?.getCreditsFor(.be) ?? 0)
      }
      VStack(alignment: .leading) {
        SmallSummary(type: "MR", count: timetableViewModel.selectedTimetable?.getCreditsFor(.mr) ?? 0)
        SmallSummary(type: "ME", count: timetableViewModel.selectedTimetable?.getCreditsFor(.me) ?? 0)
      }
      VStack(alignment: .leading) {
        SmallSummary(type: "HSE", count: timetableViewModel.selectedTimetable?.getCreditsFor(.hse) ?? 0)
        SmallSummary(type: "ETC", count: timetableViewModel.selectedTimetable?.getCreditsFor(.etc) ?? 0)
      }

      BigSummary(label: "Credit", grade: "\(timetableViewModel.selectedTimetable?.credits ?? 0)")
      BigSummary(label: "AU", grade: "\(timetableViewModel.selectedTimetable?.creditAUs ?? 0)")
      BigSummary(label: "Grade", grade: timetableViewModel.selectedTimetable?.gradeLetter ?? "?")
      BigSummary(label: "Load", grade: timetableViewModel.selectedTimetable?.loadLetter ?? "?")
      BigSummary(label: "Speech", grade: timetableViewModel.selectedTimetable?.speechLetter ?? "?")
    }
  }
}

fileprivate struct SmallSummary: View {
  let type: String
  let count: Int

  var body: some View {
    HStack(spacing: 0) {
      Text(type)
        .fontWeight(.semibold)
        .frame(width: type.count == 2 ? 24 : 26, alignment: .leading)
      Text("\(count)")
        .frame(width: 16, alignment: .leading)
    }.font(.caption)
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

