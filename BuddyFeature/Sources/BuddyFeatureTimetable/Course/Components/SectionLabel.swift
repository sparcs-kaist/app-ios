//
//  SectionLabel.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 12/10/2026.
//

import Foundation
import BuddyDomain

/// How one section of a course is told apart from the others.
///
/// Usually by its professors, but some courses, such as the Leadership ones,
/// list every section under a placeholder professor, "Staff", and tell them
/// apart by subtitle instead. Those read "A Staff, B Staff, C Staff" if labelled
/// by professor, so a subtitle comes first wherever there is one.
struct SectionLabel: Equatable {
  /// The subtitle, or without one, the professors.
  let title: String
  /// The professors, when the subtitle took the title and they are more than a
  /// placeholder.
  let professors: String?

  init(subtitle: String, professors: [Professor]) {
    let topic = Self.topic(from: subtitle)
    let names = professors.map(\.name).filter { !$0.isEmpty }
    let realNames = names.filter { !Self.isPlaceholder($0) }

    if let topic {
      title = topic
      self.professors = realNames.isEmpty ? nil : realNames.formatted(.list(type: .and, width: .narrow))
    } else {
      title = names.isEmpty
        ? String(localized: "Unknown", bundle: .module)
        : names.formatted(.list(type: .and, width: .narrow))
      self.professors = nil
    }
  }

  init(_ lecture: Lecture) {
    self.init(subtitle: lecture.subtitle, professors: lecture.professors)
  }

  init(_ lectureClass: CourseHistoryClass) {
    self.init(subtitle: lectureClass.subtitle, professors: lectureClass.professors)
  }

  /// The subtitle without the angle brackets OTL wraps it in, e.g.
  /// "<디자인 과제로부터 살아남기>", or nil when there is none.
  static func topic(from subtitle: String) -> String? {
    var topic = subtitle.trimmingCharacters(in: .whitespacesAndNewlines)
    if topic.hasPrefix("<"), topic.hasSuffix(">"), topic.count >= 2 {
      topic = String(topic.dropFirst().dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    return topic.isEmpty ? nil : topic
  }

  /// A stand-in OTL lists for a section whose instructor isn't named.
  private static func isPlaceholder(_ name: String) -> Bool {
    name.trimmingCharacters(in: .whitespaces).caseInsensitiveCompare("Staff") == .orderedSame
  }
}
