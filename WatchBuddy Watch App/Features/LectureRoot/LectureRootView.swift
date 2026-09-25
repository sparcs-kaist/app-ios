//
//  LectureRootView.swift
//  WatchBuddy Watch App
//
//  Created by Soongyu Kwon on 24/09/2026.
//

import SwiftUI
import BuddyDomain

/// Hosts the four timetable presentations behind one fixed hierarchy:
/// Week (root) → Day → Up Next, with List pushed straight on top of Week.
/// The View Options choice only decides how deep the stack starts, so the
/// back button always walks up towards the Week overview. Tapping a day
/// column pushes that Day; tapping an entry pushes Up Next paged to it.
struct LectureRootView: View {
  let timetable: Timetable

  @AppStorage("lectureViewOption") private var viewOption: LectureViewOption = .upNext
  @Environment(\.scenePhase) private var scenePhase

  @State private var path: [LectureDestination]
  @State private var showViewOptions = false

  /// The day the stack starts on, re-anchored when the app wakes on a new date.
  @State private var today: DayType = .today

  init(timetable: Timetable) {
    self.timetable = timetable
    // @AppStorage isn't readable before body, and pushing in onAppear would
    // flash the Week root first — so seed the initial stack from defaults.
    let raw = UserDefaults.standard.string(forKey: "lectureViewOption")
    let option = raw.flatMap(LectureViewOption.init(rawValue:)) ?? .upNext
    self._path = State(initialValue: Self.path(for: option, day: .today))
  }

  var body: some View {
    NavigationStack(path: $path) {
      WeekTimetableView(timetable: timetable) { day in
        path.append(.day(day))
      }
      .toolbar { optionsToolbar }
      .navigationDestination(for: LectureDestination.self) { destination in
        Group {
          switch destination {
          case .day(let day):
            DayTimetableView(timetable: timetable, day: day) { entry in
              path.append(.upNext(day: day, focusedID: entry.id))
            }
          case .list(let day):
            LectureListView(items: timetable.scheduleEntries(day: day)) { entry in
              path.append(.upNext(day: day, focusedID: entry.id))
            }
          case .upNext(let day, let focusedID):
            LectureTabView(items: timetable.scheduleEntries(day: day), initialSelection: focusedID)
          }
        }
        .toolbar { optionsToolbar }
      }
    }
    // Menu doesn't exist on watchOS; the system look for this — one grouped
    // section titled "View Options" with a checkmark — is an inline Picker
    // presented in a sheet, which is what Apple Calendar shows too.
    .sheet(isPresented: $showViewOptions) {
      NavigationStack {
        List {
          Picker("View Options", selection: selectedOption) {
            ForEach(LectureViewOption.allCases) { option in
              Label(option.title, systemImage: option.systemImage)
                .tag(option)
            }
          }
          .pickerStyle(.inline)
        }
      }
    }
    .onChange(of: scenePhase) { _, phase in
      guard phase == .active, DayType.today != today else { return }
      today = .today
      path = Self.path(for: viewOption, day: today)
    }
  }

  @ToolbarContentBuilder
  private var optionsToolbar: some ToolbarContent {
    ToolbarItemGroup(placement: .bottomBar) {
      Spacer()
      Button {
        showViewOptions = true
      } label: {
        Image(systemName: "ellipsis")
      }
    }
  }

  /// Picking an option restarts the stack from today at that option's depth.
  private var selectedOption: Binding<LectureViewOption> {
    Binding {
      viewOption
    } set: { option in
      today = .today
      viewOption = option
      path = Self.path(for: option, day: today)
      showViewOptions = false
    }
  }

  /// The stack depth each view option starts at.
  private static func path(for option: LectureViewOption, day: DayType) -> [LectureDestination] {
    switch option {
    case .week: []
    case .list: [.list(day)]
    case .day: [.day(day)]
    case .upNext: [.day(day), .upNext(day: day, focusedID: nil)]
    }
  }
}

/// The screens the Week root can lead to.
enum LectureDestination: Hashable {
  case day(DayType)
  case list(DayType)
  case upNext(day: DayType, focusedID: String?)
}

#Preview {
  LectureRootView(timetable: .mockList[0])
}
