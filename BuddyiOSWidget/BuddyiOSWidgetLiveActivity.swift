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
        .activitySystemActionForegroundColor(.primary)
        .widgetURL(URL(string: "sparcsapp://timetable"))
    } dynamicIsland: { context in
      let presentation = context.presentation
      return DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          TimetableActivityExpandedLeading(presentation)
            .padding(.leading, 4)
        }
        DynamicIslandExpandedRegion(.trailing) {
          TimetableActivityExpandedTrailing(presentation)
            .padding(.trailing, 4)
        }
        DynamicIslandExpandedRegion(.bottom) {
          TimetableActivityExpandedBottom(presentation)
            .padding(.horizontal, 4)
        }
      } compactLeading: {
        TimetableActivityBadge(presentation, diameter: 22)
      } compactTrailing: {
        TimetableActivityCompactTimer(presentation)
      } minimal: {
        TimetableActivityBadge(presentation, diameter: 22)
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
      next: .init(title: "Calculus I", buildingCode: "E6-1", kind: .lecture, colorID: 2, begin: begin + 4 * 3600)
    )
  }

  static var inProgress: Self {
    let begin = Int(Date.now.addingTimeInterval(-34 * 60).timeIntervalSince1970)
    return Self(
      phase: .upcoming,
      current: .physics(begin: begin),
      next: .init(title: "Calculus I", buildingCode: "E6-1", kind: .lecture, colorID: 2, begin: begin + 4 * 3600)
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
