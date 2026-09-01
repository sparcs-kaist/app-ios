//
//  LectureReviewPage.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 07/03/2026.
//

import Foundation

public struct LectureReviewPage: Hashable, Codable, Sendable {
  public let reviews: [LectureReview]
  public let averageGrade: Double
  public let averageLoad: Double
  public let averageSpeech: Double
  public let department: Department?
  public let totalCount: Int

  public func getGradeLetter(for credits: Int) -> String {
    letter(for: round(Double(credits) * averageGrade))
  }

  public func getLoadLetter(for credits: Int) -> String {
    letter(for: round(Double(credits) * averageLoad))
  }

  public func getSpeechLetter(for credits: Int) -> String {
    letter(for: round(Double(credits) * averageSpeech))
  }

  // safely get letter grade string
  private func letter(for value: Double) -> String {
    let index = Int(round(value))
    return Timetable.letters[safe: index] ?? "?"
  }

  public init(
    reviews: [LectureReview],
    averageGrade: Double,
    averageLoad: Double,
    averageSpeech: Double,
    department: Department?,
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
