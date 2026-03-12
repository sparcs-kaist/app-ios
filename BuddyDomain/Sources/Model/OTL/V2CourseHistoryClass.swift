//
//  V2CourseHistoryClass.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 12/03/2026.
//

import Foundation

public struct V2CourseHistoryClass: Hashable, Sendable, Codable {
  public let lectureID: Int
  public let subtitle: String
  public let section: String
  public let professors: [V2Professor]

  public init(lectureID: Int, subtitle: String, section: String, professors: [V2Professor]) {
    self.lectureID = lectureID
    self.subtitle = subtitle
    self.section = section
    self.professors = professors
  }
}
