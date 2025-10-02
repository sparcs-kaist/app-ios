//
//  DayType.swift
//  soap
//
//  Created by Soongyu Kwon on 29/12/2024.
//

enum DayType: Int, Identifiable, CaseIterable, Comparable {
    case sun = 6
    case mon = 0
    case tue = 1
    case wed = 2
    case thu = 3
    case fri = 4
    case sat = 5

    var id: String { stringValue }
    
    var stringValue: String {
        switch self {
        case .sun: return String(localized: "Sun")
        case .mon: return String(localized: "Mon")
        case .tue: return String(localized: "Tue")
        case .wed: return String(localized: "Wed")
        case .thu: return String(localized: "Thu")
        case .fri: return String(localized: "Fri")
        case .sat: return String(localized: "Sat")
        }
    }

    // Comparable conformance
    static func < (lhs: DayType, rhs: DayType) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

extension DayType {
  static var weekdays: [DayType] { [.mon, .tue, .wed, .thu, .fri] }
}
