//
//  LectureEntry.swift
//  BuddyUI
//
//  Created by Soongyu Kwon on 25/12/2025.
//

import WidgetKit
import SwiftUI
import BuddyDomain

public struct LectureEntry: TimelineEntry {
  public let date: Date
  public let lecture: Lecture?
  public let classtime: ClassTime?
  public let startDate: Date?
  public let signInRequired: Bool
  public let backgroundColor: Color
  public let relevance: TimelineEntryRelevance

  public init(
    date: Date,
    lecture: Lecture?,
    classtime: ClassTime?,
    startDate: Date?,
    signInRequired: Bool,
    backgroundColor: Color,
    relevance: TimelineEntryRelevance
  ) {
    self.date = date
    self.lecture = lecture
    self.classtime = classtime
    self.startDate = startDate
    self.signInRequired = signInRequired
    self.backgroundColor = backgroundColor
    self.relevance = relevance
  }
}
