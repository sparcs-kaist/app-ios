//
//  UpcomingClassInlineWidgetView.swift
//  soap
//
//  Created by Soongyu Kwon on 07/10/2025.
//

import SwiftUI
import BuddyDomain

public struct UpcomingClassInlineWidgetView: View {
  var entry: LectureEntry

  public init(entry: LectureEntry) {
    self.entry = entry
  }

  public var body: some View {
    if let lecture = entry.lecture, let start = entry.startDate {
      Text("\(start, style: .time) • \(lecture.title.localized())")
    } else if entry.signInRequired {
      Text("Sign in Required")
    } else {
      Text("No more classes")
    }
  }
}
