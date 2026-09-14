//
//  TimetableEntry.swift
//  BuddyUI
//
//  Created by Soongyu Kwon on 27/12/2025.
//

import WidgetKit
import SwiftUI
import BuddyDomain

public struct TimetableEntry: TimelineEntry {
  public let date: Date
  public let timetable: Timetable?
  public let signInRequired: Bool
  public let relevance: TimelineEntryRelevance
  /// Resolved by the timeline provider from this widget's configuration.
  public let theme: TimetableTheme

  public init(
    date: Date,
    timetable: Timetable?,
    signInRequired: Bool,
    relevance: TimelineEntryRelevance,
    theme: TimetableTheme = .default
  ) {
    self.date = date
    self.timetable = timetable
    self.signInRequired = signInRequired
    self.relevance = relevance
    self.theme = theme
  }
}
