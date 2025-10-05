//
//  LectureReviewDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 16/09/2025.
//

import Foundation
import BuddyDomain

struct LectureReviewDTO: Codable {
  let id: Int
  let lecture: LectureDTO
  let content: String
  let like: Int
  let grade: Int
  let load: Int
  let speech: Int
  let isDeleted: Int
  let isLiked: Bool

  enum CodingKeys: String, CodingKey {
    case id
    case lecture
    case content
    case like
    case grade
    case load
    case speech
    case isDeleted = "is_deleted"
    case isLiked = "userspecific_is_liked"
  }
}


extension LectureReviewDTO {
  func toModel() -> LectureReview {
    LectureReview(
      id: id,
      lecture: lecture.toModel(),
      content: content,
      like: like,
      grade: grade,
      load: load,
      speech: speech,
      isDeleted: isDeleted != 0,
      isLiked: isLiked
    )
  }
}
