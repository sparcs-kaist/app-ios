//
//  BuddyiOSWidgetLiveActivity.swift
//  BuddyiOSWidget
//
//  Created by Soongyu Kwon on 25/12/2025.
//

import ActivityKit
import WidgetKit
import SwiftUI
import BuddyDomain
import BuddyLiveActivityUI

struct BuddyiOSWidgetLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: TimetableActivityAttributes.self) { context in
      TimetableActivityLockScreenView(context.presentation)
        .activityBackgroundTint(.black)
        .activitySystemActionForegroundColor(.white)
        .widgetURL(URL(string: "sparcsapp://timetable"))
    } dynamicIsland: { context in
      let presentation = context.presentation
      return DynamicIsland {
        DynamicIslandExpandedRegion(.leading, priority: 1) {
          TimetableActivityExpandedLeading(presentation)
            .padding(.leading, 6)
        }
        DynamicIslandExpandedRegion(.trailing) {
          TimetableActivityExpandedTrailing(presentation)
            .padding(.trailing, 6)
        }
        DynamicIslandExpandedRegion(.bottom) {
          TimetableActivityExpandedBottom(presentation)
            .padding(.horizontal, 6)
            .padding(.top, 4)
        }
      } compactLeading: {
        TimetableActivityBadge(presentation, diameter: 26)
      } compactTrailing: {
        TimetableActivityCompactTimer(presentation)
      } minimal: {
        TimetableActivityMinimal(presentation, diameter: 24)
      }
      .keylineTint(presentation.color.onBlack)
      .widgetURL(URL(string: "sparcsapp://timetable"))
    }
  }
}

private extension ActivityViewContext<TimetableActivityAttributes> {
  /// Colours follow the theme chosen in the app, read when the system renders the activity.
  var presentation: TimetableActivityPresentation {
    TimetableActivityPresentation(
      state: state,
      isStale: isStale,
      theme: TimetableThemeStore().selectedTheme
    )
  }
}

// MARK: - Previews

private extension TimetableActivityAttributes {
  static let preview = TimetableActivityAttributes(sessionDate: "2026-10-13", sessionNo: 0)
}

private extension TimetableActivityAttributes.Item {
  static func physics(begin: Int) -> Self {
    Self(title: "General Physics I", buildingCode: "E11", buildingName: "Creative Learning Building",
         room: "101", kind: .lecture, colorID: 1, begin: begin, end: begin + 75 * 60)
  }
}

private extension TimetableActivityAttributes.ContentState {
  static var upcoming: Self {
    let begin = Int(Date.now.addingTimeInterval(12 * 60).timeIntervalSince1970)
    return Self(
      phase: .upcoming,
      current: .physics(begin: begin),
      next: .init(title: "Problem Solving", buildingCode: "W3-1", buildingName: "W3-1", room: "1501",
                  kind: .lecture, colorID: 5, begin: begin + 90 * 60)
    )
  }

  static var inProgress: Self {
    let begin = Int(Date.now.addingTimeInterval(-34 * 60).timeIntervalSince1970)
    return Self(
      phase: .upcoming,
      current: .physics(begin: begin),
      next: .init(title: "Problem Solving", buildingCode: "W3-1", buildingName: "W3-1", room: "1501",
                  kind: .lecture, colorID: 5, begin: begin + 90 * 60)
    )
  }

  static var done: Self {
    let end = Int(Date.now.addingTimeInterval(-3 * 60).timeIntervalSince1970)
    return Self(
      phase: .done,
      current: .physics(begin: end - 75 * 60),
      next: nil
    )
  }
}

#Preview("Lock Screen", as: .content, using: TimetableActivityAttributes.preview) {
  BuddyiOSWidgetLiveActivity()
} contentStates: {
  TimetableActivityAttributes.ContentState.upcoming
  TimetableActivityAttributes.ContentState.inProgress
  TimetableActivityAttributes.ContentState.done
}

#Preview("Expanded", as: .dynamicIsland(.expanded), using: TimetableActivityAttributes.preview) {
  BuddyiOSWidgetLiveActivity()
} contentStates: {
  TimetableActivityAttributes.ContentState.upcoming
  TimetableActivityAttributes.ContentState.inProgress
  TimetableActivityAttributes.ContentState.done
}

#Preview("Compact", as: .dynamicIsland(.compact), using: TimetableActivityAttributes.preview) {
  BuddyiOSWidgetLiveActivity()
} contentStates: {
  TimetableActivityAttributes.ContentState.upcoming
  TimetableActivityAttributes.ContentState.inProgress
}

#Preview("Minimal", as: .dynamicIsland(.minimal), using: TimetableActivityAttributes.preview) {
  BuddyiOSWidgetLiveActivity()
} contentStates: {
  TimetableActivityAttributes.ContentState.upcoming
  TimetableActivityAttributes.ContentState.inProgress
}
