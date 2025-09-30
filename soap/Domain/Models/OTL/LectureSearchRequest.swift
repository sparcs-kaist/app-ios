//
//  LectureSearchRequest.swift
//  soap
//
//  Created by Soongyu Kwon on 30/09/2025.
//

import Foundation

struct LectureSearchRequest {
  let semester: Semester
  let keyword: String
  let limit: Int
  let offset: Int
}
