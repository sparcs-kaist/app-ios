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
  let department: DepartmentDTO
  let majors: [DepartmentDTO]
  let departments: [DepartmentDTO]
  let favoriteDepartments: [DepartmentDTO]
  let reviewWritableLectures: [LectureDTO]
  let myTimetableLectures: [LectureDTO]

}
