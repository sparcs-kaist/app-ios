//
//  Course.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 07/03/2026.
//

import Foundation

public struct Course: Identifiable, Hashable, Sendable, Codable {
  public let id: Int
  public let name: String
  public let summary: String
  public let code: String
  public let type: LectureType
  public let department: Department
  public let history: [CourseHistory]
  public let classDuration: Int
  public let expDuration: Int
  public let credit: Int
  public let creditAU: Int

  public init(
    id: Int,
    name: String,
    summary: String,
    code: String,
    type: LectureType,
    department: Department,
    history: [CourseHistory],
    classDuration: Int,
    expDuration: Int,
    credit: Int,
    creditAU: Int
  ) {
    self.id = id
    self.name = name
    self.summary = summary
    self.code = code
    self.type = type
    self.department = department
    self.history = history
    self.classDuration = classDuration
    self.expDuration = expDuration
    self.credit = credit
    self.creditAU = creditAU
  }
}
