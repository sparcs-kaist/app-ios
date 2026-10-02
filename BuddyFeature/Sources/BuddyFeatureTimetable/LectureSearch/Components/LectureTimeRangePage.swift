//
//  LectureTimeRangePage.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 02/10/2026.
//

import SwiftUI
import BuddyDomain
import TimetableUI

/// Chooses lecture search's class time by dragging on the timetable, from the Time chip. The
/// range applies as it is drawn, so going back returns to the results already filtered.
struct LectureTimeRangePage: View {
  let timetable: Timetable?
  @Binding var time: LectureTimeFilter

  var body: some View {
    // On the theme's card, as the timetable itself is, so the theme's labels and lines read.
    ThemedGridCard {
      TimetableRangeSelector(timetable: timetable, filter: $time)
    }
    .padding()
    // As behind the timetable, so its card stands out in light mode.
    .background(Color.systemGroupedBackground)
    .safeAreaBar(edge: .bottom) {
      summary
    }
    .navigationTitle(String(localized: "Class Time", bundle: .module))
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button(String(localized: "Clear", bundle: .module)) {
          time = LectureTimeFilter()
        }
        .disabled(time.isEmpty)
      }
    }
    .toolbarVisibility(.hidden, for: .tabBar)
  }

  /// The chosen range, or how to choose one.
  private var summary: some View {
    Group {
      if time.isEmpty {
        Text("Drag down a day to choose when classes meet.", bundle: .module)
          .foregroundStyle(.secondary)
      } else {
        Text(summaryText)
          .fontWeight(.semibold)
          .contentTransition(.numericText())
      }
    }
    .font(.subheadline)
    .multilineTextAlignment(.center)
    .padding(.horizontal, 20)
    .padding(.vertical, 12)
    .glassEffect(.regular, in: .capsule)
    .padding()
    .animation(.snappy(duration: 0.2), value: time)
  }

  /// The range as the timetable shows it: an open end reads as the first or last time offered.
  private var summaryText: String {
    let times = LectureTimeFilter.selectableTimes
    let range = time.begin == nil && time.end == nil
      ? nil
      : "\(clockTime(time.begin ?? times.first!))–\(clockTime(time.end ?? times.last!))"
    return [time.day?.description, range].compactMap { $0 }.joined(separator: " ")
  }

  private func clockTime(_ minutes: Int) -> String {
    String(format: "%02d:%02d", minutes / 60, minutes % 60)
  }
}
