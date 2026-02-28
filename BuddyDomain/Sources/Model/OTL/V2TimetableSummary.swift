//
//  V2TimetableSummary.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 28/02/2026.
//

import Foundation

public struct V2TimetableSummary: Identifiable, Hashable, Sendable, Codable {
  public let id: Int
  public let name: String
  public let year: Int
  public let semester: SemesterType

  public init(id: Int, name: String, year: Int, semester: SemesterType) {
    self.id = id
    self.name = name
    self.year = year
    self.semester = semester
  }
}
