//
//  LectureGrade.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 25/09/2026.
//

import Foundation

/// A grade the user records for a lecture they took.
///
/// Raw values are persisted on-device, so never change an existing one.
public enum LectureGrade: String, CaseIterable, Sendable, Codable, Hashable {
  case pass = "P"
  case fail = "F"
  case nonRecord = "NR"
  case aPlus = "A+"
  case a = "A0"
  case aMinus = "A-"
  case bPlus = "B+"
  case b = "B0"
  case bMinus = "B-"
  case cPlus = "C+"
  case c = "C0"
  case cMinus = "C-"
  case dPlus = "D+"
  case d = "D0"
  case dMinus = "D-"
  case satisfied = "S"
  case unsatisfied = "U"

  /// Grades selectable for a lecture that carries credits.
  public static let creditOptions: [LectureGrade] = [
    .pass, .fail, .nonRecord,
    .aPlus, .a, .aMinus, .bPlus, .b, .bMinus, .cPlus, .c, .cMinus, .dPlus, .d, .dMinus
  ]

  /// Grades selectable for an AU-only lecture.
  public static let auOptions: [LectureGrade] = [.satisfied, .unsatisfied]

  public static func options(for lecture: Lecture) -> [LectureGrade] {
    lecture.isAUOnly ? auOptions : creditOptions
  }

  /// The short label shown to users, e.g. "A" for `A0`.
  public var title: String {
    switch self {
    case .a: "A"
    case .b: "B"
    case .c: "C"
    case .d: "D"
    default: rawValue
    }
  }

  /// Points on KAIST's 4.3 scale, or `nil` for grades that don't count toward GPA
  /// (P, NR, S, U). F counts as 0.
  public var gradePoint: Double? {
    switch self {
    case .aPlus: 4.3
    case .a: 4.0
    case .aMinus: 3.7
    case .bPlus: 3.3
    case .b: 3.0
    case .bMinus: 2.7
    case .cPlus: 2.3
    case .c: 2.0
    case .cMinus: 1.7
    case .dPlus: 1.3
    case .d: 1.0
    case .dMinus: 0.7
    case .fail: 0.0
    case .pass, .nonRecord, .satisfied, .unsatisfied: nil
    }
  }
}

public extension Lecture {
  /// Lectures worth only AU are graded S/U and never count toward GPA.
  var isAUOnly: Bool { credit == 0 && creditAU > 0 }
}
