//
//  V2LectureUseCaseProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 07/03/2026.
//

import Foundation

public protocol V2LectureUseCaseProtocol: Sendable {
  func searchLecture(request: LectureSearchRequest) async throws -> [V2CourseLecture]
}
