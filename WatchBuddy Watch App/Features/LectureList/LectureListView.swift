//
//  LectureListView.swift
//  WatchBuddy Watch App
//
//  Created by Soongyu Kwon on 24/09/2026.
//

import SwiftUI
import BuddyDomain
import TimetableUI

/// Today's lectures as a plain scrolling list, with no offsets for time or
/// duration — just the schedule in order.
struct LectureListView: View {
  let items: [LectureItem]

  @Environment(\.timetableTheme) private var theme

  var body: some View {
    if items.isEmpty {
      Text("There is no class today.")
        .multilineTextAlignment(.center)
    } else {
      List(items) { item in
        HStack(spacing: 8) {
          RoundedRectangle(cornerRadius: 2)
            .fill(theme.color(forCourseID: item.lecture.courseID))
            .frame(width: 4)

          VStack(alignment: .leading, spacing: 2) {
            Text(item.lecture.name)
              .font(.headline)
              .lineLimit(2)
              .minimumScaleFactor(0.8)
            Text(item.lectureClass.description)
              .font(.caption)
              .foregroundStyle(.secondary)
            Text(item.lectureClass.location)
              .font(.caption2)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }

          Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
      }
    }
  }
}

#Preview {
  NavigationStack {
    LectureListView(
      items: Lecture.mockList.map { LectureItem(lecture: $0, lectureClass: $0.classes.first!) }
    )
  }
}
