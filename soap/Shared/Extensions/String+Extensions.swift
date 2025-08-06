//
//  String+Extensions.swift
//  soap
//
//  Created by Soongyu Kwon on 04/01/2025.
//

import Foundation

extension String {
  func toDate() -> Date? {
    let formatter = ISO8601DateFormatter()

    // Try with fractional seconds first
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = formatter.date(from: self) {
      return date
    }

    // Fallback to no fractional seconds
    formatter.formatOptions = [.withInternetDateTime]
    return formatter.date(from: self)
  }
}

extension String {
  var urlEscaped: String {
    addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
  }
}

