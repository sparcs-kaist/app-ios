//
//  DayType.swift
//  soap
//
//  Created by Soongyu Kwon on 29/12/2024.
//

enum DayType: Int, Identifiable, CaseIterable, Comparable {
    case sun = 0
    case mon = 1
    case tue = 2
    case wed = 3
    case thu = 4
    case fri = 5
    case sat = 6

    var id: String { stringValue }
    
    var stringValue: String {
        switch self {
        case .sun: return "Sun"
        case .mon: return "Mon"
        case .tue: return "Tue"
        case .wed: return "Wed"
        case .thu: return "Thu"
        case .fri: return "Fri"
        case .sat: return "Sat"
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
