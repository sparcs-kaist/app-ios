//
//  V2LectureItem+Mockable.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 09/03/2026.
//

import Foundation

extension V2LectureItem: Mockable { }

public extension V2LectureItem {
  static var mock: V2LectureItem {
    let lecture = V2Lecture.mock
    return V2LectureItem(lecture: lecture, lectureClass: lecture.classes[0])
  }

  static var mockList: [V2LectureItem] {
    let lectures = V2Lecture.mockList
    return [
      V2LectureItem(lecture: lectures[0], lectureClass: lectures[0].classes[0]),
      V2LectureItem(lecture: lectures[0], lectureClass: lectures[0].classes[1]),
      V2LectureItem(lecture: lectures[1], lectureClass: lectures[1].classes[0])
    ]
  }
}
