import Foundation
import Testing
import Moya
import BuddyDomain
@testable import BuddyDataCore

@Suite("Timetable theme sharing")
struct TimetableThemeSharingTests {
  private let json = #"{"code":"ABC123","theme":{"name":"Ocean","hexColors":["123456","ABCDEF"],"textColorHex":"FFFFFF","separatorColorHex":"111111","backgroundColorHex":"222222","gridLabelColorHex":"333333"}}"#

  @Test func normalizesOnlySixASCIICharacters() {
    #expect(TimetableThemeShareCode.normalized(" abC123\n") == "ABC123")
    for invalid in ["", "ABC12", "ABC1234", "ABC!23", "ＡＢＣ１２３", "abcß12", "AB C12"] {
      #expect(TimetableThemeShareCode.normalized(invalid) == nil)
    }
  }

  @Test func payloadOmitsLocalIdentityAndPreservesColors() throws {
    let theme = TimetableTheme.default
    let data = try JSONEncoder().encode(TimetableThemePayload(theme))
    let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    #expect(json["id"] == nil)
    #expect(json["isBuiltIn"] == nil)
    #expect(json["hexColors"] as? [String] == theme.hexColors)
    #expect(json["name"] as? String == theme.displayName)
  }

  @Test func importsIndependentEditableCopies() async throws {
    let repository = makeRepository(status: 200)
    let first = try await repository.fetch(code: "abc123")
    let second = try await repository.fetch(code: "ABC123")
    #expect(first.id != second.id)
    #expect(first.id.hasPrefix("custom."))
    #expect(!first.isBuiltIn)
    #expect(first.name == "Ocean")
    #expect(first.hexColors == ["123456", "ABCDEF"])
    #expect(first.separatorColorHex == "111111")
    #expect(first.backgroundColorHex == "222222")
    #expect(first.gridLabelColorHex == "333333")
    #expect(try await repository.share(.default) == "ABC123")
  }

  @Test func propagatesMissingCodeAndServerErrors() async {
    for status in [404, 429, 500] {
      let repository = makeRepository(status: status)
      await #expect(throws: NetworkError.self) {
        _ = try await repository.fetch(code: "ABC123")
      }
    }
  }

  private func makeRepository(status: Int) -> TimetableThemeRepository {
    let data = Data(json.utf8)
    let provider = MoyaProvider<TimetableThemeTarget>(endpointClosure: { target in
      Endpoint(url: URL(target: target).absoluteString,
               sampleResponseClosure: { .networkResponse(status, data) },
               method: target.method, task: target.task, httpHeaderFields: target.headers)
    }, stubClosure: MoyaProvider.immediatelyStub)
    return TimetableThemeRepository(provider: provider)
  }
}
