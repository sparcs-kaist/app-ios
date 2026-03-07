//
//  V2CoursePageDTO.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 07/03/2026.
//

import Foundation

struct V2CoursePageDTO: Codable {
  let courses: [V2CourseSummaryDTO]
  let totalCount: Int
}
