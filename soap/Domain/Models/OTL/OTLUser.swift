//
//  OTLUser.swift
//  soap
//
//  Created by Soongyu Kwon on 18/09/2025.
//

import Foundation

struct OTLUser: Identifiable {
  let id: Int
  let email: String
  let studentID: String
  let firstName: String
  let lastName: String
  let department: Department
  let majors: [Department]
  let reviewWritableLectures: [Lecture]
  let myTimetableLectures: [Lecture]
  let reviews: [LectureReview]
}
