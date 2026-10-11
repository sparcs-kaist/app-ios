//
//  LectureSearchFilter.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 30/09/2026.
//

import Foundation

/// The advanced options that narrow a lecture search. An empty set means "any".
public struct LectureSearchFilter: Equatable, Hashable, Sendable {
  public var departmentIDs: Set<Int>
  public var classifications: Set<Classification>
  public var levels: Set<Level>

  public init(
    departmentIDs: Set<Int> = [],
    classifications: Set<Classification> = [],
    levels: Set<Level> = []
  ) {
    self.departmentIDs = departmentIDs
    self.classifications = classifications
    self.levels = levels
  }

  public var isEmpty: Bool {
    departmentIDs.isEmpty && classifications.isEmpty && levels.isEmpty
  }
}

extension LectureSearchFilter {
  /// Course classification. The raw value is the code the OTL API filters by.
  public enum Classification: String, CaseIterable, Identifiable, Sendable {
    case br = "BR"
    case be = "BE"
    case mr = "MR"
    case me = "ME"
    case mgc = "MGC"
    case hse = "HSE"
    case gr = "GR"
    case eg = "EG"
    case oe = "OE"

    public var id: String { rawValue }

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
      case .mgc:
        LocalizedString(["en": "Mandatory General Courses", "ko": "교양필수"])
      case .hse:
        LocalizedString(["en": "Humanities and Social Elective", "ko": "인문사회선택"])
      case .gr:
        LocalizedString(["en": "General Required", "ko": "공통필수"])
      case .eg:
        LocalizedString(["en": "Elective (Graduate)", "ko": "선택(석/박사)"])
      case .oe:
        LocalizedString(["en": "Other Elective", "ko": "자유선택"])
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
      case .mgc:
        String(localized: "MGC", bundle: .module)
      case .hse:
        String(localized: "HSE", bundle: .module)
      case .gr:
        String(localized: "GR", bundle: .module)
      case .eg:
        String(localized: "EG", bundle: .module)
      case .oe:
        String(localized: "OE", bundle: .module)
      }
    }
  }

  /// Course number band. `graduate` covers every level from 500 upwards.
  public enum Level: Int, CaseIterable, Identifiable, Sendable {
    case level100 = 100
    case level200 = 200
    case level300 = 300
    case level400 = 400
    case graduate = 500

    public var id: Int { rawValue }
  }
}
