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
  /// The activity time range this entry shows, when it isn't a lecture.
  public let activitySlot: TimetableActivitySlot?
  public var activity: TimetableActivity? { activitySlot?.activity }
  public var title: String? { activity?.title ?? lecture?.name }
  public var location: String? { activity?.location ?? lectureClass?.location }
  public var timeDescription: String? {
    if let slot = activitySlot {
      return Date.formattedTimeRange(minutesPastMidnight: slot.begin, to: slot.end)
    }
    return lectureClass?.description
  }
  public let lecture: Lecture?
  public let lectureClass: LectureClass?
  public let startDate: Date?
  public let signInRequired: Bool
  public let backgroundColor: Color
  public let relevance: TimelineEntryRelevance

  public init(
    date: Date,
    lecture: Lecture?,
    lectureClass: LectureClass?,
    startDate: Date?,
    signInRequired: Bool,
    backgroundColor: Color,
    relevance: TimelineEntryRelevance,
    activitySlot: TimetableActivitySlot? = nil
  ) {
    self.activitySlot = activitySlot
    self.date = date
    self.lecture = lecture
    self.lectureClass = lectureClass
    self.startDate = startDate
    self.signInRequired = signInRequired
    self.backgroundColor = backgroundColor
    self.relevance = relevance
  }
}
