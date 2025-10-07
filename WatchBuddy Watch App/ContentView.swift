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
  @AppStorage("timetableData", store: UserDefaults(suiteName: "group.org.sparcs.soap")!) private var timetableData: Data = .init()
  @Environment(\.scenePhase) private var scenePhase

  @State private var items: [LectureItem] = []

  private var timetable: Timetable? {
    guard !timetableData.isEmpty else { return nil }
    return try? JSONDecoder().decode(Timetable.self, from: timetableData)
  }

  var body: some View {
    Group {
      if timetable != nil {
        NavigationStack {
          LectureTabView(items: items)
        }
      } else {
        Text("Please open Buddy app on your iPhone to sync your timetable for this semester.")
          .multilineTextAlignment(.center)
      }
    }
    .onAppear {
      recomputeItems()
    }
    .onChange(of: scenePhase) { phase, _ in
      if phase == .active { recomputeItems() }
    }
    .onChange(of: timetableData) { _, _ in
      recomputeItems()
    }
  }

  private func recomputeItems(date: Date = Date()) {
    if let timetable {
      items = timetable.lectureItems(for: date)
    }
  }
}

#Preview {
  ContentView()
}

