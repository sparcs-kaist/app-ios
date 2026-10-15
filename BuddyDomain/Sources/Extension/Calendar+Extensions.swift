//
//  Calendar+Extensions.swift
//  soap
//
//  Created by Soongyu Kwon on 11/07/2025.
//

import Foundation

public extension Calendar {
  /// KAIST's calendar. Classes happen in Korea Standard Time wherever the device is,
  /// so absolute class times are always derived in Asia/Seoul.
  static var kaist: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
    calendar.locale = Locale(identifier: "ko_KR")
    return calendar
  }

  func startOfWeek(for date: Date) -> Date {
    let components = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)

    return self.date(from: components) ?? date
  }
}
