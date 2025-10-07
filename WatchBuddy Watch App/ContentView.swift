//
//  ContentView.swift
//  WatchBuddy Watch App
//
//  Created by Soongyu Kwon on 04/10/2025.
//

import SwiftUI
import Factory
import BuddyDomain

struct ContentView: View {
  @AppStorage("timetableData") private var timetableData: Data = .init()

  private var timetable: Timetable? {
    guard !timetableData.isEmpty else { return nil }
    return try? JSONDecoder().decode(Timetable.self, from: timetableData)
  }

  var body: some View {
    Group {
      if timetable != nil {
        NavigationStack {
          LectureTabView(items: todayLectureItems())
        }
      } else {
        Text("Please open Buddy app on your iPhone to sync your timetable for this semester.")
          .multilineTextAlignment(.center)
      }
    }
  }

  private func todayLectureItems() -> [LectureItem] {
    guard let timetable else { return [] }
    let today = DayType.from(date: Date(), calendar: .current)

    var items: [LectureItem] = []
    for lecture in timetable.lectures {
      for (i, ct) in lecture.classTimes.enumerated() where ct.day == today {
        items.append(LectureItem(lecture: lecture, index: i))
      }
    }

    return items.sorted {
      let a = $0.lecture.classTimes[$0.index].begin
      let b = $1.lecture.classTimes[$1.index].begin
      return a < b
    }
  }
}

#Preview {
  ContentView()
}

