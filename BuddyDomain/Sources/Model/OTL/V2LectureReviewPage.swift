//
//  V2LectureReviewPage.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 07/03/2026.
//

import Foundation

public struct V2LectureReviewPage: Hashable, Codable, Sendable {
  public let reviews: [V2LectureReview]
  public let averageGrade: Double
  public let averageLoad: Double
  public let averageSpeech: Double
  public let department: V2Department?
  public let totalCount: Int

  public init(
    reviews: [V2LectureReview],
    averageGrade: Double,
    averageLoad: Double,
    averageSpeech: Double,
    department: V2Department?,
    totalCount: Int
  ) {
    self.reviews = reviews
    self.averageGrade = averageGrade
    self.averageLoad = averageLoad
    self.averageSpeech = averageSpeech
    self.department = department
    self.totalCount = totalCount
  }
}
