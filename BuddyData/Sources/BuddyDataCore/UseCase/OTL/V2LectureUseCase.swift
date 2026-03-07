//
//  V2LectureUseCase.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 07/03/2026.
//

import Foundation
import BuddyDomain

public final class V2LectureUseCase: V2LectureUseCaseProtocol, Sendable {
  // MARK: - Dependencies
  private let otlLectureRepository: OTLV2LectureRepositoryProtocol

  // MARK: - Initialiser
  public init(otlLectureRepository: OTLV2LectureRepositoryProtocol) {
    self.otlLectureRepository = otlLectureRepository
  }

  // MARK: - Functions
  public func searchLecture(request: LectureSearchRequest) async throws -> [V2CourseLecture] {
    try await otlLectureRepository.searchLecture(request: request)
  }
}
