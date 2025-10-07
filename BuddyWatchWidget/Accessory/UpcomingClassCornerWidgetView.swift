//
//  UpcomingClassCornerWidgetView.swift
//  soap
//
//  Created by Soongyu Kwon on 07/10/2025.
//

import SwiftUI

struct UpcomingClassCornerWidgetView: View {
  var entry: LectureEntry

  var body: some View {
    if let lecture = entry.lecture, let start = entry.startDate {
      Text(start, style: .time)
        .widgetCurvesContent()
        .widgetLabel(lecture.title.localized())
    } else if entry.signInRequired {
      Text("")
        .widgetCurvesContent()
        .widgetLabel("Sign in Required")
    } else {
      Text("")
        .widgetCurvesContent()
        .widgetLabel("No more classes")
    }
  }
}
