import Testing
import BuddyDomain
import BuddyTestSupport
@testable import BuddyDataCore

@Suite("Timetable theme use case")
struct TimetableThemeUseCaseTests {
  @Test func normalizesCodeBeforeCallingRepository() async throws {
    let mockRepo = MockTimetableThemeRepository()
    let useCase = TimetableThemeUseCase(timetableThemeRepository: mockRepo, crashlyticsService: nil)
    let theme = try await useCase.fetch(code: " abC123\n")
    #expect(await mockRepo.codes == ["ABC123"])
    #expect(theme == .default)
  }

  @Test func invalidCodeDoesNotCallRepository() async {
    let mockRepo = MockTimetableThemeRepository()
    let useCase = TimetableThemeUseCase(timetableThemeRepository: mockRepo, crashlyticsService: nil)
    await #expect(throws: NetworkError.self) {
      _ = try await useCase.fetch(code: "ABC!23")
    }
    #expect(await mockRepo.codes.isEmpty)
  }

  @Test func sharesOriginalThemeAndReturnsCode() async throws {
    let mockRepo = MockTimetableThemeRepository()
    let useCase = TimetableThemeUseCase(timetableThemeRepository: mockRepo, crashlyticsService: nil)
    let theme = TimetableTheme.default.duplicated(named: "Ocean")
    #expect(try await useCase.share(theme) == "ABC123")
    #expect(await mockRepo.sharedThemes == [theme])
  }

  @Test func preservesNotFoundAndRecordsFailure() async {
    let mockRepo = MockTimetableThemeRepository(fails: true)
    let crashlytics = MockCrashlyticsService()
    let useCase = TimetableThemeUseCase(timetableThemeRepository: mockRepo, crashlyticsService: crashlytics)
    do {
      _ = try await useCase.fetch(code: "ABC123")
      Issue.record("Expected missing theme error")
    } catch NetworkError.notFound {
      #expect(crashlytics.recordErrorWithContextCallCount == 1)
      #expect(crashlytics.lastRecordedContext?.feature == "TimetableTheme")
    } catch {
      Issue.record("Unexpected error: \(error)")
    }
  }
}

private actor MockTimetableThemeRepository: TimetableThemeRepositoryProtocol {
  var codes: [String] = []
  var sharedThemes: [TimetableTheme] = []
  let fails: Bool

  init(fails: Bool = false) { self.fails = fails }

  func share(_ theme: TimetableTheme) async throws -> String {
    sharedThemes.append(theme)
    return "ABC123"
  }

  func fetch(code: String) async throws -> TimetableTheme {
    codes.append(code)
    if fails { throw NetworkError.notFound }
    return .default
  }
}
