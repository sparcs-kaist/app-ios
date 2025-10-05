//
//  OTLUserDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 15/09/2025.
//

import Foundation
import BuddyDomain

public struct OTLUserDTO: Codable {
  public let id: Int
  public let email: String
  public let studentID: String
  public let firstName: String
  public let lastName: String
  public let department: DepartmentDTO?
  public let majors: [DepartmentDTO]
  public let reviewWritableLectures: [LectureDTO]
  public let myTimetableLectures: [LectureDTO]
  public let reviews: [LectureReviewDTO]

  enum CodingKeys: String, CodingKey {
    case id
    case email
    case studentID = "student_id"
    case firstName
    case lastName
    case department
    case majors
    case reviewWritableLectures = "review_writable_lectures"
    case myTimetableLectures = "my_timetable_lectures"
    case reviews
  }
}


public extension OTLUserDTO {
  func toModel() -> OTLUser {
    OTLUser(
      id: id,
      email: email,
      studentID: studentID,
      firstName: firstName,
      lastName: lastName,
      department: department?.toModel(),
      majors: majors.compactMap { $0.toModel() },
      reviewWritableLectures: reviewWritableLectures.compactMap { $0.toModel() },
      myTimetableLectures: myTimetableLectures.compactMap { $0.toModel() },
      reviews: reviews.compactMap { $0.toModel() }
    )
  }
}
