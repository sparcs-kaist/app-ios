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
  public let timetable: V2Timetable?
  public let signInRequired: Bool
  public let relevance: TimelineEntryRelevance

  public init(
    date: Date,
    timetable: V2Timetable?,
    signInRequired: Bool,
    relevance: TimelineEntryRelevance
  ) {
    self.date = date
    self.timetable = timetable
    self.signInRequired = signInRequired
    self.relevance = relevance
  }
}
