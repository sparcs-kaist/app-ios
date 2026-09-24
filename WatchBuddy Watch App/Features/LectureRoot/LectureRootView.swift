//
//  LectureRootView.swift
//  WatchBuddy Watch App
//
//  Created by Soongyu Kwon on 24/09/2026.
//

import SwiftUI
import BuddyDomain

/// Hosts the four timetable presentations and the ellipsis button that opens
/// View Options. Navigation between the modes mirrors Apple Calendar on
/// watchOS: Week → tap a day column → Day → tap a lecture → Up Next paged to
/// that lecture. Picking a mode from the sheet always restarts from today.
struct LectureRootView: View {
  let timetable: Timetable

  @AppStorage("lectureViewOption") private var viewOption: LectureViewOption = .upNext
  @Environment(\.scenePhase) private var scenePhase

  @State private var selectedDay: DayType = .today
  @State private var focusedItemID: String? = nil
  @State private var showViewOptions = false

  /// Tracks the day the current selection was made on, so waking the app on a
  /// later date snaps back to that day's schedule.
  @State private var anchoredToday: DayType = .today

  private var dayItems: [LectureItem] {
    timetable.getLectures(day: selectedDay)
      .sorted { $0.lectureClass.begin < $1.lectureClass.begin }
  }

  var body: some View {
    NavigationStack {
      Group {
        switch viewOption {
        case .upNext:
          LectureTabView(items: dayItems, initialSelection: focusedItemID)
        case .list:
          LectureListView(items: dayItems) { item in
            focusedItemID = item.id
            viewOption = .upNext
          }
        case .day:
          DayTimetableView(timetable: timetable, day: selectedDay, focusedItemID: focusedItemID) { item in
            focusedItemID = item.id
            viewOption = .upNext
          }
        case .week:
          WeekTimetableView(timetable: timetable) { day in
            selectedDay = day
            focusedItemID = nil
            viewOption = .day
          }
        }
      }
      .toolbar {
        ToolbarItemGroup(placement: .bottomBar) {
          Spacer()
          Button {
            showViewOptions = true
          } label: {
            Image(systemName: "ellipsis")
          }
        }
      }
    }
    .sheet(isPresented: $showViewOptions) {
      ViewOptionsView(selection: viewOption) { option in
        selectedDay = .today
        focusedItemID = nil
        viewOption = option
        showViewOptions = false
      }
    }
    .onChange(of: scenePhase) { _, phase in
      guard phase == .active, DayType.today != anchoredToday else { return }
      anchoredToday = .today
      selectedDay = anchoredToday
      focusedItemID = nil
    }
  }
}

#Preview {
  LectureRootView(timetable: .mockList[0])
}
