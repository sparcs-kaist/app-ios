//
//  OTLUserDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 15/09/2025.
//

import Foundation

struct OTLUserDTO: Codable {
  let id: Int
  let email: String
  let studentID: String
  let firstName: String
  let lastName: String
  let department: DepartmentDTO?
  let majors: [DepartmentDTO]
  let reviewWritableLectures: [LectureDTO]
  let myTimetableLectures: [LectureDTO]
  let reviews: [LectureReviewDTO]

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


extension OTLUserDTO {
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
