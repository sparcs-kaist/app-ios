//
//  CourseHistoryClass.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 12/03/2026.
//

import Foundation

public struct CourseHistoryClass: Hashable, Sendable, Codable {
  public let lectureID: Int
  public let subtitle: String
  public let section: String
  public let professors: [Professor]

  public init(lectureID: Int, subtitle: String, section: String, professors: [Professor]) {
    self.lectureID = lectureID
    self.subtitle = subtitle
    self.section = section
    self.professors = professors
  }
}
