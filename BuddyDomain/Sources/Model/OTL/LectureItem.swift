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
