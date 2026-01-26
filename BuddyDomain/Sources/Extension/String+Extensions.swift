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
