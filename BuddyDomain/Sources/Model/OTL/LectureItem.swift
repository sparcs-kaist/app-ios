//
//  LectureItem.swift
//  soap
//
//  Created by Soongyu Kwon on 29/06/2025.
//

import SwiftUI

// LectureItem is designed to deliver Lecture with specific ClassTimes index.

public struct V2LectureItem: Identifiable {
  public let id = UUID()
  public let lecture: V2Lecture
  public let lectureClass: V2LectureClass

  public init(lecture: V2Lecture, lectureClass: V2LectureClass) {
    self.lecture = lecture
    self.lectureClass = lectureClass
  }
}
