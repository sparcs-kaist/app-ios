//
//  LectureUseCase.swift
//  BuddyData
//
//  Created by Soongyu Kwon on 07/03/2026.
//

import Foundation
import BuddyDomain

public final class LectureUseCase: LectureUseCaseProtocol, Sendable {
  // MARK: - Dependencies
  private let otlLectureRepository: OTLLectureRepositoryProtocol

  // MARK: - Initialiser
  public init(otlLectureRepository: OTLLectureRepositoryProtocol) {
    self.otlLectureRepository = otlLectureRepository
  }

  // MARK: - Functions
  public func searchLecture(request: LectureSearchRequest) async throws -> [CourseLecture] {
    try await otlLectureRepository.searchLecture(request: request)
  }
}
