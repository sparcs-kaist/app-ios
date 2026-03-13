//
//  CourseSummary.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 07/03/2026.
//

import Foundation

public struct CourseSummary: Identifiable, Sendable, Hashable, Codable {
  public let id: Int
  public let code: String
  public let name: String
  public let summary: String
  public let department: Department
  public let professors: [Professor]
  public let type: LectureType
  public let completed: Bool
  public let open: Bool

  public init(
    id: Int,
    code: String,
    name: String,
    summary: String,
    department: Department,
    professors: [Professor],
    type: LectureType,
    completed: Bool,
    open: Bool
  ) {
    self.id = id
    self.code = code
    self.name = name
    self.summary = summary
    self.department = department
    self.professors = professors
    self.type = type
    self.completed = completed
    self.open = open
  }
}
