import BuddyDomain

public final class TimetableThemeUseCase: TimetableThemeUseCaseProtocol {
  private let timetableThemeRepository: TimetableThemeRepositoryProtocol
  private let crashlyticsService: CrashlyticsServiceProtocol?

  public init(
    timetableThemeRepository: TimetableThemeRepositoryProtocol,
    crashlyticsService: CrashlyticsServiceProtocol?
  ) {
    self.timetableThemeRepository = timetableThemeRepository
    self.crashlyticsService = crashlyticsService
  }

  public func share(_ theme: TimetableTheme) async throws -> String {
    try await execute(operation: "share") {
      try await timetableThemeRepository.share(theme)
    }
  }

  public func fetch(code: String) async throws -> TimetableTheme {
    guard let code = TimetableThemeShareCode.normalized(code) else {
      throw NetworkError.notFound
    }
    return try await execute(operation: "fetch") {
      try await timetableThemeRepository.fetch(code: code)
    }
  }

  private func execute<T>(operation: String, _ action: () async throws -> T) async throws -> T {
    do {
      return try await action()
    } catch {
      crashlyticsService?.record(
        error: error,
        context: CrashContext(feature: "TimetableTheme", metadata: ["operation": operation])
      )
      throw error
    }
  }
}
