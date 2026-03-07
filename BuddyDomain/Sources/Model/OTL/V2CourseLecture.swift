//
//  V2CourseLecture.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 06/03/2026.
//

import Foundation

public struct V2CourseLecture: Identifiable, Equatable, Sendable {
  public let id: Int
  public let name: String
  public let code: String
  public let type: LectureType
  public let lectures: [V2Lecture]
  public let completed: Bool

  public init(
    id: Int,
    name: String,
    code: String,
    type: LectureType,
    lectures: [V2Lecture],
    completed: Bool
  ) {
    self.id = id
    self.name = name
    self.code = code
    self.type = type
    self.lectures = lectures
    self.completed = completed
  }
}
