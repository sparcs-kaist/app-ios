//
//  LectureReviewDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 16/09/2025.
//

import Foundation
import BuddyDomain

public struct LectureReviewDTO: Codable {
  public let id: Int
  public let lecture: LectureDTO
  public let content: String
  public let like: Int
  public let grade: Int
  public let load: Int
  public let speech: Int
  public let isDeleted: Int
  public let isLiked: Bool

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


public extension LectureReviewDTO {
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
