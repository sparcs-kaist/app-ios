//
//  LectureReviewPage.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 07/03/2026.
//

import Foundation
import BuddyDomain

struct LectureReviewPageDTO: Codable {
  let reviews: [LectureReviewDTO]
  let averageGrade: Double
  let averageLoad: Double
  let averageSpeech: Double
  let department: DepartmentDTO?
  let totalCount: Int
}


extension LectureReviewPageDTO {
  func toModel() -> LectureReviewPage {
    LectureReviewPage(
      reviews: reviews.compactMap { $0.toModel() },
      averageGrade: averageGrade,
      averageLoad: averageLoad,
      averageSpeech: averageSpeech,
      department: department?.toModel(),
      totalCount: totalCount
    )
  }
}
