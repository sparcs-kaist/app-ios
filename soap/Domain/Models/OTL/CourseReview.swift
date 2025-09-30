//
//  CourseReview.swift
//  soap
//
//  Created by 하정우 on 10/1/25.
//

import Foundation

struct CourseReview: Sendable, Identifiable, Equatable {
  static let letters: [String] = ["?", "F", "D", "C", "B", "A"]
  
  let id: Int
  let content: String
  let professor: LocalizedString?
  let year: Int
  let semester: SemesterType
  let grade: Int
  let like: Int
  let load: Int
  let speech: Int
  let isDeleted: Bool
  let isLiked: Bool
}

extension CourseReview {
  // Letter grade for the grade
  var gradeLetter: String {
    if grade > CourseReview.letters.count { return "?" }
    return CourseReview.letters[grade]
  }

  // Letter grade for the load
  var loadLetter: String {
    if grade > CourseReview.letters.count { return "?" }
    return CourseReview.letters[load]
  }

  // Letter grade for the speech
  var speechLetter: String {
    if grade > CourseReview.letters.count { return "?" }
    return CourseReview.letters[speech]
  }
}
