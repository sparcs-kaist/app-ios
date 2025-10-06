//
//  SemesterType.swift
//  soap
//
//  Created by Soongyu Kwon on 04/01/2025.
//

public enum SemesterType: String, Comparable, Sendable, Codable {
  case spring = "Spring"
  case summer = "Summer"
  case autumn = "Autumn"
  case winter = "Winter"

  // Comparable
  public static func < (lhs: SemesterType, rhs: SemesterType) -> Bool {
    let order: [SemesterType] = [.spring, .summer, .autumn, .winter]
    return order.firstIndex(of: lhs)! < order.firstIndex(of: rhs)!
  }

  public var shortCode: String {
    switch self {
    case .spring:
      "S"
    case .summer:
      "U"
    case .autumn:
      "F"
    case .winter:
      "W"
    }
  }

  public var intValue: Int {
    switch self {
    case .spring:
      1
    case .summer:
      2
    case .autumn:
      3
    case .winter:
      4
    }
  }

  public var description: String {
    switch self {
    case .spring:
      String(localized: "Spring")
    case .summer:
      String(localized: "Summer")
    case .autumn:
      String(localized: "Autumn")
    case .winter:
      String(localized: "Winter")
    }
  }
}


extension SemesterType {
  public static func fromRawValue(_ rawValue: Int) -> SemesterType {
    switch rawValue {
    case 1:
      .spring
    case 2:
      .summer
    case 3:
      .autumn
    case 4:
      .winter
    default:
      .spring
    }
  }
}
