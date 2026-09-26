//
//  LectureType.swift
//  soap
//
//  Created by Soongyu Kwon on 29/12/2024.
//

import Foundation

public enum LectureType: String, Equatable, Sendable, Codable {
  case br = "BR"
  case be = "BE"
  case mr = "MR"
  case me = "ME"
  /// An HSS elective without a subcategory (older curricula).
  case hse = "HSE"
  case hseCore = "HSE_CORE"
  case hseGeneral = "HSE_GENERAL"
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
    case .hseCore:
      LocalizedString(["en": "Humanities and Social Elective (Core)", "ko": "인문사회선택(핵심)"])
    case .hseGeneral:
      LocalizedString(["en": "Humanities and Social Elective (General)", "ko": "인문사회선택(일반)"])
    case .etc:
      LocalizedString(["en": "ETC", "ko": "기타"])
    }
  }

  public var shortCode: String {
    switch self {
    case .br:
      String(localized: "BR", bundle: .module)
    case .be:
      String(localized: "BE", bundle: .module)
    case .mr:
      String(localized: "MR", bundle: .module)
    case .me:
      String(localized: "ME", bundle: .module)
    case .hse:
      String(localized: "HSE", bundle: .module)
    case .hseCore:
      String(localized: "HSE-C", bundle: .module)
    case .hseGeneral:
      String(localized: "HSE-G", bundle: .module)
    case .etc:
      String(localized: "ETC", bundle: .module)
    }
  }
}

extension LectureType {
  public static func fromRawValue(_ rawValue: String) -> LectureType {
    // The API appends a subcategory to HSS electives, in the request's language, e.g.
    // "인문사회선택(인문-핵심)" / "Humanities & Social Elective(Social-General)".
    let parts = rawValue.split(separator: "(", maxSplits: 1, omittingEmptySubsequences: false)
    let baseType = parts.first.map { $0.trimmingCharacters(in: .whitespaces) } ?? rawValue
    let subcategory = parts.count > 1 ? parts[1].lowercased() : ""

    if isHSEBaseType(baseType) {
      return hseType(subcategory: subcategory)
    }

    return switch baseType {
    case "Basic Required", "기초필수":
      .br
    case "Basic Elective", "기초선택":
      .be
    case "Major Required", "전공필수":
      .mr
    case "Major Elective", "전공선택":
      .me
    default:
      .etc
    }
  }

  /// "인문사회선택" / "인선", or "Humanities & Social Elective" (also spelt with "and").
  private static func isHSEBaseType(_ baseType: String) -> Bool {
    let normalized = baseType.replacingOccurrences(of: " ", with: "").lowercased()
    return normalized.hasPrefix("인문사회") || normalized.hasPrefix("인선") || normalized.hasPrefix("humanities")
  }

  private static func hseType(subcategory: String) -> LectureType {
    if subcategory.contains("핵심") || subcategory.contains("core") { return .hseCore }
    if subcategory.contains("일반") || subcategory.contains("general") { return .hseGeneral }
    return .hse
  }
}
