//
//  CompactTimetableSelector.swift
//  soap
//
//  Created by Soongyu Kwon on 05/01/2025.
//

import Foundation
import SwiftUI
import BuddyDomain

struct CompactTimetableSelector: View {
  let semesters: [Semester]
  @Binding var selectedSemester: Semester?
  let timetables: [TimetableSummary]
  @Binding var selectedTimetableID: Int?
  let createTimetable: () async -> Void
  let renameTimetable: (String) async -> Void
  let deleteTimetable: () async -> Void
  let isWide: Bool

  var body: some View {
    ZStack {
      HStack {
        if isWide {
          Spacer()
        }

        SemesterSelector(
          semesters: semesters,
          selectedSemester: $selectedSemester
        )

        if !isWide {
          Spacer()
        }

        TableSelector(
          timetables: timetables,
          selectedTimetableID: $selectedTimetableID,
          createTimetable: createTimetable,
          renameTimetable: renameTimetable,
          deleteTimetable: deleteTimetable
        )
      }
    }
    .frame(height: 30)
  }
}

#Preview {
//  CompactTimetableSelector()
//    .environment(TimetableViewModel())
//    .background(
//      Color(UIColor.systemGroupedBackground)
//    )
}
