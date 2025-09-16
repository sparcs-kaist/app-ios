//
//  LectureType.swift
//  soap
//
//  Created by Soongyu Kwon on 29/12/2024.
//

enum LectureType: Equatable {
  case br         // Basic Required
  case be         // Basic Elective
  case mr         // Major Required
  case me         // Major Elective
  case hse        // Humanities and Social Elective
  case etc
}

extension LectureType {
  static func fromRawValue(_ rawValue: String) -> LectureType {
    switch rawValue {
    case "Basic Required":
        .br
    case "Basic Elective":
      .be
    case "Major Required":
      .mr
    case "Major Elective":
      .me
    case "Humanities and Social Elective":
      .hse
    default:
      .etc
    }
  }
}
