//
//  LectureReviewDTO.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 06/03/2026.
//

import Foundation
import BuddyDomain

struct LectureReviewDTO: Codable {
  let id: Int
  let courseId: Int
  let lectureId: Int
  let courseName: String
  let professors: [ProfessorDTO]
  let year: Int
  let semester: Int
  let content: String
  let like: Int
  let grade: Int
  let load: Int
  let speech: Int
  let isDeleted: Bool
  let likedByUser: Bool
}


extension LectureReviewDTO {
  func toModel() -> LectureReview {
    LectureReview(
      id: id,
      courseID: courseId,
      lectureID: lectureId,
      courseName: courseName,
      professors: professors.compactMap { $0.toModel() },
      year: year,
      semester: SemesterType.fromRawValue(semester),
      content: content,
      like: like,
      grade: ratingToString(grade),
      load: ratingToString(load),
      speech: ratingToString(speech),
      isDeleted: isDeleted,
      likedByUser: likedByUser
    )
  }

  private func ratingToString(_ rating: Int) -> String {
    switch rating {
    case 1:
      "F"
    case 2:
      "D"
    case 3:
      "C"
    case 4:
      "B"
    case 5:
      "A"
    default:
      "?"
    }
  }
}
