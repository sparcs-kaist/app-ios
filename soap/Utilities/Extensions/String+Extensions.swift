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
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        return dateFormatter.date(from: self)
    }
}

extension String {
  var urlEscaped: String {
    addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
  }
}
