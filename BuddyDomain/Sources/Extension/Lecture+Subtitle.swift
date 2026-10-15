//
//  Lecture+Subtitle.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 12/10/2026.
//

import Foundation

public extension Lecture {
  /// The section's subtitle as people read it, or nil when it has none. It tells
  /// sections of one course apart, as for the Leadership courses, whose sections
  /// all list the placeholder professor "Staff".
  var subtitleTopic: String? {
    Self.topic(fromSubtitle: subtitle)
  }

  /// A subtitle without the angle brackets OTL wraps it in, e.g.
  /// "<디자인 과제로부터 살아남기>", or nil when there is none.
  static func topic(fromSubtitle subtitle: String) -> String? {
    var topic = subtitle.trimmingCharacters(in: .whitespacesAndNewlines)
    if topic.hasPrefix("<"), topic.hasSuffix(">"), topic.count >= 2 {
      topic = String(topic.dropFirst().dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    return topic.isEmpty ? nil : topic
  }
}
