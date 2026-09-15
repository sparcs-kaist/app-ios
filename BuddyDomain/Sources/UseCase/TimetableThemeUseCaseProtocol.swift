public protocol TimetableThemeUseCaseProtocol: Sendable {
  func share(_ theme: TimetableTheme) async throws -> String
  func fetch(code: String) async throws -> TimetableTheme
}
