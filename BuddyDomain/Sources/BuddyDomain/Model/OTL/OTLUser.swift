//
//  OTLUser.swift
//  soap
//
//  Created by Soongyu Kwon on 18/09/2025.
//

import Foundation

public struct OTLUser: Identifiable, Sendable {
  public let id: Int
  public let email: String
  public let studentID: String
  public let firstName: String
  public let lastName: String
  public let department: Department?
  public let majors: [Department]
  public let reviewWritableLectures: [Lecture]
  public let myTimetableLectures: [Lecture]
  public let reviews: [LectureReview]

  public init(
    id: Int,
    email: String,
    studentID: String,
    firstName: String,
    lastName: String,
    department: Department?,
    majors: [Department],
    reviewWritableLectures: [Lecture],
    myTimetableLectures: [Lecture],
    reviews: [LectureReview]
  ) {
    self.id = id
    self.email = email
    self.studentID = studentID
    self.firstName = firstName
    self.lastName = lastName
    self.department = department
    self.majors = majors
    self.reviewWritableLectures = reviewWritableLectures
    self.myTimetableLectures = myTimetableLectures
    self.reviews = reviews
  }
}
