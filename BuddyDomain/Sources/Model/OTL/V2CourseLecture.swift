//
//  CourseLecture.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 06/03/2026.
//

import Foundation

public struct CourseLecture: Identifiable, Equatable, Hashable, Sendable {
  public let id: Int
  public let name: String
  public let code: String
  public let type: LectureType
  public let lectures: [Lecture]
  public let completed: Bool

  public init(
    id: Int,
    name: String,
    code: String,
    type: LectureType,
    lectures: [Lecture],
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

extension Array where Element == CourseLecture {
  /// Appends the next page of search results. The API pages by lecture, so a course can straddle
  /// two pages; its sections are folded into the course already in the list.
  public func appending(page: [CourseLecture]) -> [CourseLecture] {
    var merged = self
    for course in page {
      guard let index = merged.firstIndex(where: { $0.id == course.id }) else {
        merged.append(course)
        continue
      }
      let existing = merged[index]
      let knownIDs = Set(existing.lectures.map(\.id))
      merged[index] = CourseLecture(
        id: existing.id,
        name: existing.name,
        code: existing.code,
        type: existing.type,
        lectures: existing.lectures + course.lectures.filter { !knownIDs.contains($0.id) },
        completed: existing.completed
      )
    }
    return merged
  }
}
