//
//  V2Course.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 07/03/2026.
//

import Foundation

public struct V2Course: Identifiable, Hashable, Sendable, Codable {
  public let id: Int
  public let name: String
  public let summary: String
  public let code: String
  public let type: LectureType
  public let department: V2Department
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
    department: V2Department,
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
    self.classDuration = classDuration
    self.expDuration = expDuration
    self.credit = credit
    self.creditAU = creditAU
  }
}
