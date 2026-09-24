//
//  LectureListView.swift
//  WatchBuddy Watch App
//
//  Created by Soongyu Kwon on 24/09/2026.
//

import SwiftUI
import BuddyDomain
import TimetableUI

/// The day's lectures and activities as a plain scrolling list, with no
/// offsets for time or duration — just the schedule in order. Each row is a
/// full-colour card in the entry's theme colour, like a timetable grid cell.
/// Tapping an entry hands it back so the root can jump to Up Next at it.
struct LectureListView: View {
  let items: [ScheduleEntry]
  let onSelect: (ScheduleEntry) -> Void

  @Environment(\.timetableTheme) private var theme

  var body: some View {
    if items.isEmpty {
      Text("There is no class today.")
        .multilineTextAlignment(.center)
    } else {
      List(items) { entry in
        Button {
          onSelect(entry)
        } label: {
          VStack(alignment: .leading, spacing: 2) {
            Text(entry.title)
              .font(.headline)
              .lineLimit(2)
              .minimumScaleFactor(0.8)
            Text(entry.classTime.description)
              .font(.caption)
              .opacity(0.8)
            Text(entry.location)
              .font(.caption2)
              .opacity(0.8)
              .lineLimit(1)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .foregroundStyle(theme.textColor)
        }
        .listRowBackground(
          RoundedRectangle(cornerRadius: 10)
            .fill(entry.color(in: theme))
        )
      }
    }
  }
}

#Preview {
  NavigationStack {
    LectureListView(
      items: Lecture.mockList.map { .lecture(LectureItem(lecture: $0, lectureClass: $0.classes.first!)) }
    ) { _ in }
  }
}
