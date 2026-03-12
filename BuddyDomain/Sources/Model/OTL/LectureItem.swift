//
//  LectureItem.swift
//  soap
//
//  Created by Soongyu Kwon on 29/06/2025.
//

import SwiftUI

// LectureItem is designed to deliver Lecture with specific ClassTimes index.

public struct LectureItem: Identifiable {
  public let id = UUID()
  public let lecture: Lecture
  public let lectureClass: LectureClass

  public init(lecture: Lecture, lectureClass: LectureClass) {
    self.lecture = lecture
    self.lectureClass = lectureClass
  }
}
