//
//  TimetableSharingUseCase.swift
//  BuddyData
//

import BuddyDomain

public final class TimetableSharingUseCase: TimetableSharingUseCaseProtocol {
  private let otlTimetableRepository: OTLTimetableRepositoryProtocol
  private let crashlyticsService: CrashlyticsServiceProtocol?

  public init(
    otlTimetableRepository: OTLTimetableRepositoryProtocol,
    crashlyticsService: CrashlyticsServiceProtocol?
  ) {
    self.otlTimetableRepository = otlTimetableRepository
    self.crashlyticsService = crashlyticsService
  }

  public func fetchSharableTerms() async throws -> Set<FriendTimetableTerm> {
    try await execute(operation: "fetchSharableTerms") {
      async let shared = otlTimetableRepository.getSharedSemesters()
      async let owned = otlTimetableRepository.getTableList()
      let ownedTerms = try await owned.map { FriendTimetableTerm(year: $0.year, semester: $0.semester) }
      return Set(try await shared).union(ownedTerms)
    }
  }

  public func fetchSharing(semester: Semester) async throws -> TimetableSharing {
    try await execute(operation: "fetchSharing") {
      try await otlTimetableRepository.getSharing(year: semester.year, semester: semester.semesterType)
    }
  }

  public func share(timetableID: Int?, semester: Semester) async throws {
    try await execute(operation: "share") {
      try await otlTimetableRepository.setSharedTimetable(
        year: semester.year,
        semester: semester.semesterType,
        timetableID: timetableID
      )
    }
  }

  private func execute<T>(operation: String, _ action: () async throws -> T) async throws -> T {
    do {
      return try await action()
    } catch {
      crashlyticsService?.record(
        error: error,
        context: CrashContext(feature: "TimetableSharing", metadata: ["operation": operation])
      )
      throw error
    }
  }
}
