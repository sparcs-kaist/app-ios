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

extension String {
  func toHTMLParagraphs() -> String {
    self
      .components(separatedBy: "\n") // split by newlines
      .map { "<p>\($0)</p>" }        // wrap each in <p>
      .joined()                      // join them back
  }
}

extension String {
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
      logger.error("Error converting HTML: \(error)")
      return ""
    }
  }
}
