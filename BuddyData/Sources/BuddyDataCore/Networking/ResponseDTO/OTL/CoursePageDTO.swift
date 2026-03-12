//
//  CoursePageDTO.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 07/03/2026.
//

import Foundation

struct CoursePageDTO: Codable {
  let courses: [CourseSummaryDTO]
  let totalCount: Int
}
