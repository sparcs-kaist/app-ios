//
//  LectureReview.swift
//  soap
//
//  Created by Soongyu Kwon on 18/09/2025.
//

import Foundation

struct LectureReview: Identifiable {
  static let letters: [String] = ["?", "F", "D", "C", "B", "A"]

  let id: Int
  let lecture: Lecture
  let content: String
  var like: Int
  let grade: Int
  let load: Int
  let speech: Int
  var isDeleted: Bool
  var isLiked: Bool
}


extension LectureReview {
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
