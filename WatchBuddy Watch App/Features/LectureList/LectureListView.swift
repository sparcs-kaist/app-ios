//
//  LectureListView.swift
//  WatchBuddy Watch App
//
//  Created by Soongyu Kwon on 24/09/2026.
//

import SwiftUI
import BuddyDomain
import TimetableUI

/// The day's lectures as a plain scrolling list, with no offsets for time or
/// duration — just the schedule in order. Each row is a full-colour card in
/// the lecture's theme colour, like a timetable grid cell. Tapping a lecture
/// hands it back so the root can jump to the Day view at that lecture.
struct LectureListView: View {
  let items: [LectureItem]
  let onSelectLecture: (LectureItem) -> Void

  @Environment(\.timetableTheme) private var theme

  var body: some View {
    if items.isEmpty {
      Text("There is no class today.")
        .multilineTextAlignment(.center)
    } else {
      List(items) { item in
        Button {
          onSelectLecture(item)
        } label: {
          VStack(alignment: .leading, spacing: 2) {
            Text(item.lecture.name)
              .font(.headline)
              .lineLimit(2)
              .minimumScaleFactor(0.8)
            Text(item.lectureClass.description)
              .font(.caption)
              .opacity(0.8)
            Text(item.lectureClass.location)
              .font(.caption2)
              .opacity(0.8)
              .lineLimit(1)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .foregroundStyle(theme.textColor)
        }
        .listRowBackground(
          RoundedRectangle(cornerRadius: 10)
            .fill(theme.color(forCourseID: item.lecture.courseID))
        )
      }
    }
  }
}

#Preview {
  NavigationStack {
    LectureListView(
      items: Lecture.mockList.map { LectureItem(lecture: $0, lectureClass: $0.classes.first!) }
    ) { _ in }
  }
}
