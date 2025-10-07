//
//  DayType.swift
//  soap
//
//  Created by Soongyu Kwon on 29/12/2024.
//

import Foundation

public enum DayType: Int, Identifiable, CaseIterable, Comparable, Sendable, Codable {
    case sun = 6
    case mon = 0
    case tue = 1
    case wed = 2
    case thu = 3
    case fri = 4
    case sat = 5

    public var id: String { stringValue }

    public var stringValue: String {
        switch self {
        case .sun: return String(localized: "Sun", bundle: .module)
        case .mon: return String(localized: "Mon", bundle: .module)
        case .tue: return String(localized: "Tue", bundle: .module)
        case .wed: return String(localized: "Wed", bundle: .module)
        case .thu: return String(localized: "Thu", bundle: .module)
        case .fri: return String(localized: "Fri", bundle: .module)
        case .sat: return String(localized: "Sat", bundle: .module)
        }
    }

    // Comparable conformance
    public static func < (lhs: DayType, rhs: DayType) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

extension DayType {
  public static var weekdays: [DayType] { [.mon, .tue, .wed, .thu, .fri] }
}

public extension DayType {
  static func from(date: Date, calendar: Calendar = .current) -> DayType {
    let weekday = calendar.component(.weekday, from: date) // 1...7
    // Index 0: Sun, 1: Mon, ..., 6: Sat
    let map: [DayType] = [.sun, .mon, .tue, .wed, .thu, .fri, .sat]
    return map[weekday - 1]
  }
}
