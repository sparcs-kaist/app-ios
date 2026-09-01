//
//  LectureItem.swift
//  soap
//
//  Created by Soongyu Kwon on 29/06/2025.
//

import SwiftUI

// LectureItem is designed to deliver Lecture with specific ClassTimes index.

public struct LectureItem: Identifiable, Hashable {
  public let lecture: Lecture
  public let lectureClass: LectureClass

  /// Content-derived identity: a given lecture + class time is always the same
  /// item. Deriving `id` from the content (rather than a fresh `UUID()`) means
  /// recomputing `todayLectures`/`nextLecture` yields equal items, so
  /// `sheet(item:)`, `.animation`, and `.onChange` can dedupe correctly.
  public var id: String {
    "\(lecture.id)-\(lectureClass.day)-\(lectureClass.begin)-\(lectureClass.end)"
  }

  public init(lecture: Lecture, lectureClass: LectureClass) {
    self.lecture = lecture
    self.lectureClass = lectureClass
  }
}
