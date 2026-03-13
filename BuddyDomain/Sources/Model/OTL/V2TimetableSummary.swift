//
//  TimetableSummary.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 28/02/2026.
//

import Foundation

public struct TimetableSummary: Identifiable, Hashable, Sendable, Codable {
  public let id: Int
  public var title: String
  public let year: Int
  public let semester: SemesterType

  public init(id: Int, title: String, year: Int, semester: SemesterType) {
    self.id = id
    self.title = title
    self.year = year
    self.semester = semester
  }
}
