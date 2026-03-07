//
//  V2LectureReview.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 06/03/2026.
//

import Foundation

public struct V2LectureReview: Identifiable, Hashable, Sendable, Codable {
  public let id: Int
  public let courseID: Int
  public let lectureID: Int
  public let courseName: String
  public let professors: [V2Professor]
  public let year: Int
  public let semester: SemesterType
  public let content: String
  public var like: Int
  public let grade: String
  public let load: String
  public let speech: String
  public let isDeleted: Bool
  public var likedByUser: Bool

  public init(
    id: Int,
    courseID: Int,
    lectureID: Int,
    courseName: String,
    professors: [V2Professor],
    year: Int,
    semester: SemesterType,
    content: String,
    like: Int,
    grade: String,
    load: String,
    speech: String,
    isDeleted: Bool,
    likedByUser: Bool
  ) {
    self.id = id
    self.courseID = courseID
    self.lectureID = lectureID
    self.courseName = courseName
    self.professors = professors
    self.year = year
    self.semester = semester
    self.content = content
    self.like = like
    self.grade = grade
    self.load = load
    self.speech = speech
    self.isDeleted = isDeleted
    self.likedByUser = likedByUser
  }
}
