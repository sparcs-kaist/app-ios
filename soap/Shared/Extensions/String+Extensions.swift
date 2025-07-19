//
//  String+Extensions.swift
//  soap
//
//  Created by Soongyu Kwon on 04/01/2025.
//

import Foundation

extension String {
  // Converts an ISO 8601 date string to a `Date` object.
  // - Returns: A `Date` object if the string is valid, otherwise `nil`.
  func toDate() -> Date? {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    return formatter.date(from: self)
  }
}

extension String {
  var urlEscaped: String {
    addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
  }
}

