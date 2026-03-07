//
//  V2LectureReviewPage.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 07/03/2026.
//

import Foundation
import BuddyDomain

struct V2LectureReviewPageDTO: Codable {
  let reviews: [V2LectureReviewDTO]
  let averageGrade: Double
  let averageLoad: Double
  let averageSpeech: Double
  let department: V2DepartmentDTO?
  let totalCount: Int
}


extension V2LectureReviewPageDTO {
  func toModel() -> V2LectureReviewPage {
    V2LectureReviewPage(
      reviews: reviews.compactMap { $0.toModel() },
      averageGrade: averageGrade,
      averageLoad: averageLoad,
      averageSpeech: averageSpeech,
      department: department?.toModel(),
      totalCount: totalCount
    )
  }
}
