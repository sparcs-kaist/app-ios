//
//  UpcomingClassCornerWidgetView.swift
//  soap
//
//  Created by Soongyu Kwon on 07/10/2025.
//

import SwiftUI
import BuddyDomain
import WidgetKit

public struct UpcomingClassCornerWidgetView: View {
  var entry: LectureEntry

  public init(entry: LectureEntry) {
    self.entry = entry
  }

  public var body: some View {
    if let lecture = entry.lecture, let start = entry.startDate {
      Text(start, style: .time)
        .widgetCurvesContent()
        .widgetLabel(lecture.title.localized())
    } else if entry.signInRequired {
      signInRequiredView
    } else {
      emptyView
    }
  }

  var signInRequiredView: some View {
    Text("")
      .widgetCurvesContent()
      .widgetLabel("Sign in Required")
  }

  var emptyView: some View {
    Text("")
      .widgetCurvesContent()
      .widgetLabel("No more classes")
  }
}
