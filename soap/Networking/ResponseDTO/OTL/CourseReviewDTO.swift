//
//  CourseReviewDTO.swift
//  soap
//
//  Created by 하정우 on 10/1/25.
//

import Foundation
import SwiftyBeaver

struct CourseReviewDTO: Codable, Identifiable {
  let id: Int
  let content: String
  let lecture: LectureDTO
  let grade: Int
  let like: Int
  let load: Int
  let speech: Int
  let isDeleted: Int
  let isLiked: Bool
  
  enum CodingKeys: String, CodingKey {
    case id, content, lecture, grade, like, load, speech
    case isDeleted = "is_deleted"
    case isLiked = "userspecific_is_liked"
  }
}

extension CourseReviewDTO {
  func toModel() -> CourseReview {
    let lecture = lecture.toModel()
    
    return CourseReview(
      id: id,
      content: content,
      professor: lecture.professors.first?.name,
      year: lecture.year,
      semester: lecture.semester,
      grade: grade,
      like: like,
      load: load,
      speech: speech,
      isDeleted: isDeleted != 0,
      isLiked: isLiked
    )
  }
}
