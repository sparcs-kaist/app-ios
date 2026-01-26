//
//  Date+Extensions.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 05/10/2025.
//

import Foundation

public extension Date {
  var toISO8601: String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    formatter.timeZone = TimeZone(secondsFromGMT: 0)

    return formatter.string(from: self)
  }
}
