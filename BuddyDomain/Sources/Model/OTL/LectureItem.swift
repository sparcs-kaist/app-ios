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
  public let index: Int         // Index for ClassTime

  public init(lecture: Lecture, index: Int) {
    self.lecture = lecture
    self.index = index
  }
}

public struct V2LectureItem: Identifiable {
  public let id = UUID()
  public let lecture: V2Lecture
  public let lectureClass: V2LectureClass

  public init(lecture: V2Lecture, lectureClass: V2LectureClass) {
    self.lecture = lecture
    self.lectureClass = lectureClass
  }
}
