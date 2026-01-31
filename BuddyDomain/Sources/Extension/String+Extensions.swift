//
//  String+Extensions.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 05/10/2025.
//

import Foundation

public extension String {
  func toHTMLParagraphs() -> String {
    self
      .components(separatedBy: "\n") // split by newlines
      .map { "<p>\($0)</p>" }        // wrap each in <p>
      .joined()                      // join them back
  }
}

public extension String {
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

public extension String {
  func convertFromHTML() -> String {
    guard let data = self.data(using: .utf8) else {
      return ""
    }

    do {
      let attributedString = try NSAttributedString(
        data: data,
        options: [
          .documentType: NSAttributedString.DocumentType.html,
          .characterEncoding: String.Encoding.utf8.rawValue
        ],
        documentAttributes: nil
      )
      return attributedString.string
    } catch {
      return ""
    }
  }
}

public extension String {
  var urlEscaped: String {
    addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
  }

  /// Formats the string as a Korean phone number in the form `XXX-XXXX-XXXX`.
  ///
  /// This method extracts only numeric characters from the receiver and then
  /// applies the `XXX-XXXX-XXXX` mask. It is intended for 11-digit Korean
  /// mobile numbers (including the leading `0`), but will format as many
  /// digits as are available, left to right, ignoring any non-digit characters.
  ///
  /// - Returns: A string containing the extracted digits formatted according
  ///   to the `XXX-XXXX-XXXX` pattern.
  func formatPhoneNumber() -> String {

    let cleanNumber = self.filter { $0.isNumber }

    let mask = "XXX-XXXX-XXXX"

    var result = ""
    var startIndex = cleanNumber.startIndex
    let endIndex = cleanNumber.endIndex

    for char in mask where startIndex < endIndex {
      if char == "X" {
        result.append(cleanNumber[startIndex])
        startIndex = cleanNumber.index(after: startIndex)
      } else {
        result.append(char)
      }
    }

    return result
  }
}
