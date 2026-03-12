//
//  OTLLectureRepositoryProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 07/03/2026.
//

import Foundation

public protocol OTLLectureRepositoryProtocol: Sendable {
  func searchLecture(request: LectureSearchRequest) async throws -> [CourseLecture]
}
