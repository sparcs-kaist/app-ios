//
//  LectureCreditData.swift
//  soap
//
//  Created by Soongyu Kwon on 20/09/2025.
//

import Foundation

struct LectureCreditData: Identifiable {
  let lectureType: LectureType
  let credits: Int
  var id: String { lectureType.rawValue }

  static let mockList: [LectureCreditData] = [
    .init(lectureType: .br, credits: 6),
    .init(lectureType: .be, credits: 3),
    .init(lectureType: .mr, credits: 3),
    .init(lectureType: .me, credits: 0),
    .init(lectureType: .hse, credits: 3),
    .init(lectureType: .etc, credits: 3),
  ]
}
