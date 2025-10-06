//
//  LectureType.swift
//  soap
//
//  Created by Soongyu Kwon on 29/12/2024.
//

public enum LectureType: String, Equatable, Sendable, Codable {
  case br = "BR"
  case be = "BE"
  case mr = "MR"
  case me = "ME"
  case hse = "HSE"
  case etc = "ETC"

  public var displayName: LocalizedString {
    switch self {
    case .br:
      LocalizedString(["en": "Basic Required", "ko": "기초필수"])
    case .be:
      LocalizedString(["en": "Basic Elective", "ko": "기초선택"])
    case .mr:
      LocalizedString(["en": "Major Required", "ko": "전공필수"])
    case .me:
      LocalizedString(["en": "Major Elective", "ko": "전공선택"])
    case .hse:
      LocalizedString(["en": "Humanities and Social Elective", "ko": "인문사회선택"])
    case .etc:
      LocalizedString(["en": "ETC", "ko": "기타"])
    }
  }
}

extension LectureType {
  public static func fromRawValue(_ rawValue: String) -> LectureType {
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
