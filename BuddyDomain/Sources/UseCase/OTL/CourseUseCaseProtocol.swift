//
//  CourseUseCaseProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 07/03/2026.
//

import Foundation

public protocol CourseUseCaseProtocol: Sendable {
  func searchCourse(request: CourseSearchRequest) async throws -> [CourseSummary]
  func getCourse(courseID: Int) async throws -> Course
}
