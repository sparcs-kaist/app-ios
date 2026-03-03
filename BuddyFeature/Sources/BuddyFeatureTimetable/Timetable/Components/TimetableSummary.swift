//
//  TimetableSummary.swift
//  soap
//
//  Created by Soongyu Kwon on 30/12/2024.
//

import SwiftUI
import Charts
import BuddyDomain

struct TimetableSummary: View {
  let selectedTimetable: V2Timetable?

  var body: some View {
    content
  }

  private var content: some View {
    HStack {
      Spacer()
      BigSummary(label: String(localized: "Credit"), grade: "\(selectedTimetable?.credits ?? 0)")
      Spacer()
      BigSummary(label: String(localized: "AU"), grade: "\(selectedTimetable?.creditAUs ?? 0)")
      Spacer()
      BigSummary(label: String(localized: "Grade"), grade: selectedTimetable?.gradeLetter ?? "?")
      Spacer()
      BigSummary(label: String(localized: "Load"), grade: selectedTimetable?.loadLetter ?? "?")
      Spacer()
      BigSummary(label: String(localized: "Speech"), grade: selectedTimetable?.speechLetter ?? "?")
      Spacer()
    }
  }
}

fileprivate struct BigSummary: View {
  let label: String
  let grade: String

  var body: some View {
    VStack(spacing: 8) {
      Text(grade)
        .foregroundStyle(.secondary)
        .fontDesign(.rounded)
        .fontWeight(.semibold)
      Text(label)
        .foregroundStyle(.tertiary)
        .font(.caption2)
        .fontWeight(.medium)
        .textCase(.uppercase)
    }
  }
}

//#Preview {
//  TimetableSummary()
//    .environment(TimetableViewModel())
//}

