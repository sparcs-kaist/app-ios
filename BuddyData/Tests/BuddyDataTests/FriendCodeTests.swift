import Testing
import BuddyDomain

/// Codes must match otlplus-server's `^[ACDEFHJKLMNPQRTUVWXY3479]{6}$`.
@Suite("Friend code")
struct FriendCodeTests {
  @Test func acceptsTheServersAlphabet() {
    #expect(FriendCode.normalized("ACD347") == "ACD347")
    #expect(FriendCode.normalized(" acd347\n") == "ACD347")
    #expect(FriendCode.normalized("YXWV97") == "YXWV97")
  }

  @Test(arguments: ["ACD34B", "0ACD34", "ACD341", "ACDO34", "ACD3I4", "ACD34", "ACD3477", "ACD 34", "가ACD34"])
  func rejectsAnythingElse(_ code: String) {
    #expect(FriendCode.normalized(code) == nil)
  }

  @Test func sanitizingKeepsOnlyCodeCharacters() {
    #expect(FriendCode.sanitized("acd-347") == "ACD347")
    #expect(FriendCode.sanitized("B0O1I8ACD") == "ACD")
    #expect(FriendCode.sanitized("ACD347XYZ") == "ACD347")
  }
}
