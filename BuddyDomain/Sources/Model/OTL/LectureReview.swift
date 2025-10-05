//
//  LectureReview.swift
//  soap
//
//  Created by Soongyu Kwon on 18/09/2025.
//

import Foundation

public struct LectureReview: Identifiable, Sendable {
  public static let letters: [String] = ["?", "F", "D", "C", "B", "A"]

  public let id: Int
  public let lecture: Lecture
  public let content: String
  public var like: Int
  public let grade: Int
  public let load: Int
  public let speech: Int
  public var isDeleted: Bool
  public var isLiked: Bool

  public init(
    id: Int,
    lecture: Lecture,
    content: String,
    like: Int,
    grade: Int,
    load: Int,
    speech: Int,
    isDeleted: Bool,
    isLiked: Bool
  ) {
    self.id = id
    self.lecture = lecture
    self.content = content
    self.like = like
    self.grade = grade
    self.load = load
    self.speech = speech
    self.isDeleted = isDeleted
    self.isLiked = isLiked
  }
}


public extension LectureReview {
  // Letter grade for the grade
  var gradeLetter: String {
    if grade > LectureReview.letters.count { return "?" }
    return LectureReview.letters[grade]
  }

  // Letter grade for the load
  var loadLetter: String {
    if load > LectureReview.letters.count { return "?" }
    return LectureReview.letters[load]
  }

  // Letter grade for the speech
  var speechLetter: String {
    if speech > LectureReview.letters.count { return "?" }
    return LectureReview.letters[speech]
  }
}
