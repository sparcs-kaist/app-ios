//
//  LectureReviewDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 16/09/2025.
//

import Foundation

struct LectureReviewDTO: Codable {
  let id: Int
  let course: CourseDTO
  let lecture: LectureDTO
  let content: String
  let like: Int
  let grade: Int
  let load: Int
  let speech: Int
  let isLiked: Bool

  enum CodingKeys: String, CodingKey {
    case id
    case course
    case lecture
    case content
    case like
    case grade
    case load
    case speech
    case isLiked = "userspecific_is_liked"
  }
}
