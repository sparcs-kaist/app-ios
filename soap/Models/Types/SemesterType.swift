//
//  SemesterType.swift
//  soap
//
//  Created by Soongyu Kwon on 04/01/2025.
//

enum SemesterType: String, Comparable {
    case spring = "Spring"
    case summer = "Summer"
    case autumn = "Autumn"
    case winter = "Winter"

    // Comparable
    static func < (lhs: SemesterType, rhs: SemesterType) -> Bool {
        let order: [SemesterType] = [.spring, .summer, .autumn, .winter]
        return order.firstIndex(of: lhs)! < order.firstIndex(of: rhs)!
    }
}
