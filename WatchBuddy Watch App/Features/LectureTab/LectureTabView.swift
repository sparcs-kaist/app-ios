//
//  LectureTabView.swift
//  soap
//
//  Created by Soongyu Kwon on 06/10/2025.
//

import SwiftUI
import BuddyDomain

struct LectureTabView: View {
  let items: [ScheduleEntry]
  /// Page to this entry instead of the upcoming one, e.g. when arriving
  /// from a tap on the Day or List view.
  var initialSelection: String? = nil

  @State private var selection: String? = nil

  var body: some View {
    if !items.isEmpty {
      TabView(selection: $selection) {
        ForEach(items) { entry in
          LectureView(entry: entry)
            .containerBackground(entry.backgroundColor.gradient, for: .tabView)
            .navigationTitle(entry.classTime.description)
            .tag(entry.id)
        }
      }
      .tabViewStyle(.verticalPage)
      .onAppear {
        selection = initialSelection ?? defaultSelection()?.id
      }
    } else {
      Text("There is no class today.")
        .multilineTextAlignment(.center)
    }
  }

  private func defaultSelection() -> ScheduleEntry? {
    let now = Calendar.current.component(.hour, from: Date()) * 60 +
    Calendar.current.component(.minute, from: Date())

    // Look for the next entry that starts after `now`
    if let next = items.first(where: { $0.classTime.begin >= now }) {
      return next
    }
    // Otherwise, fallback to the last one (probably already ongoing/just ended)
    return items.last
  }
}

#Preview {
  NavigationStack {
    LectureTabView(
      items: Lecture.mockList.map { .lecture(LectureItem(lecture: $0, lectureClass: $0.classes.first!)) }
    )
  }
}
