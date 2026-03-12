//
//  LectureItem+Mockable.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 09/03/2026.
//

import Foundation

extension LectureItem: Mockable { }

public extension LectureItem {
  static var mock: LectureItem {
    let lecture = Lecture.mock
    return LectureItem(lecture: lecture, lectureClass: lecture.classes[0])
  }

  static var mockList: [LectureItem] {
    let lectures = Lecture.mockList
    return [
      LectureItem(lecture: lectures[0], lectureClass: lectures[0].classes[0]),
      LectureItem(lecture: lectures[0], lectureClass: lectures[0].classes[1]),
      LectureItem(lecture: lectures[1], lectureClass: lectures[1].classes[0])
    ]
  }
}
