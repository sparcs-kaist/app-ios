//
//  OTLV2CourseRepositoryProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 07/03/2026.
//

import Foundation

public protocol OTLV2CourseRepositoryProtocol: Sendable {
  func searchCourse(request: CourseSearchRequest) async throws -> [V2CourseSummary]
  func getCourse(courseID: Int) async throws -> V2Course
}
