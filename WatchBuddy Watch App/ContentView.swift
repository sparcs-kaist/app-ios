//
//  ContentView.swift
//  WatchBuddy Watch App
//
//  Created by Soongyu Kwon on 04/10/2025.
//

import SwiftUI
import Factory
import BuddyDomain
import TimetableUI

struct ContentView: View {
  @AppStorage("timetableData", store: UserDefaults(suiteName: "group.org.sparcs.soap")!) private var timetableData: Data = .init()

  // The theme mirrors the iPhone's Settings choice. Observed here so a theme
  // push from the phone repaints a watch app that's already on screen —
  // lecture colours read `TimetableTheme.current`, which has no other trigger.
  @AppStorage(TimetableThemeStore.selectedThemeIDKey, store: TimetableThemeStore.sharedDefaults)
  private var selectedThemeID: String = TimetableTheme.default.id
  @AppStorage(TimetableThemeStore.customThemesKey, store: TimetableThemeStore.sharedDefaults)
  private var customThemesData: Data = .init()

  private var timetable: Timetable? {
    guard !timetableData.isEmpty else { return nil }
    return try? JSONDecoder().decode(Timetable.self, from: timetableData)
  }

  /// Changes whenever the synced theme does, rebuilding the rows so they re-read
  /// their colours. Covers an edit to the active theme, not just a new selection.
  private var themeRevision: Int {
    var hasher = Hasher()
    hasher.combine(selectedThemeID)
    hasher.combine(customThemesData)
    return hasher.finalize()
  }

  var body: some View {
    if let timetable {
      LectureRootView(timetable: timetable)
        .id(themeRevision)
        .timetableThemeFromSettings()
    } else {
      Text("Please open Buddy app on your iPhone to sync your timetable for this semester.")
        .multilineTextAlignment(.center)
    }
  }
}

#Preview {
  ContentView()
}
