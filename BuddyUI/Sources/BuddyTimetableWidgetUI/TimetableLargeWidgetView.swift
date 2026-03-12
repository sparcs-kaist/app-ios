//
//  TimetableLargeWidgetView.swift
//  BuddyUI
//
//  Created by Soongyu Kwon on 27/12/2025.
//

import SwiftUI
import BuddyDomain
import TimetableUI

public struct TimetableLargeWidgetView: View {
  var entry: TimetableEntry

  public init(entry: TimetableEntry) {
    self.entry = entry
  }

  public var body: some View {
    TimetableGrid(
      selectedTimetable: entry.timetable,
      candidateLecture: nil,
      selectedLecture: nil,
      onDelete: { _ in },
      placement: .widget
    )
  }
}
