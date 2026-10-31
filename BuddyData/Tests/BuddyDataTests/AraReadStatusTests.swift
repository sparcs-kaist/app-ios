import Testing
import Foundation
import BuddyDomain
@testable import BuddyDataCore

@Suite("Ara read status")
struct AraReadStatusTests {
  @Test(arguments: [
    ("N", AraPost.ReadStatus.unread),
    ("-", .read),
    ("U", .updated),
  ])
  func mapsServerCodes(code: String, expected: AraPost.ReadStatus) {
    #expect(AraPost.ReadStatus(rawValue: code) == expected)
  }

  @Test func ignoresUnknownCodes() {
    #expect(AraPost.ReadStatus(rawValue: "") == nil)
    #expect(AraPost.ReadStatus(rawValue: "R") == nil)
  }
}

@Suite("Ara name type")
struct AraNameTypeTests {
  @Test(arguments: [
    (1, AraPostNicknameType.regular),
    (2, .anonymous),
    (4, .realName),
  ])
  func mapsServerCodes(code: Int, expected: AraPostNicknameType) {
    #expect(AraPostNicknameType(code: code) == expected)
  }

  @Test func ignoresUnknownCodes() {
    #expect(AraPostNicknameType(code: 0) == nil)
    #expect(AraPostNicknameType(code: 3) == nil)
  }

  /// Board flags as the API sends them: Market 1, Talk 3, With School 4.
  @Test(arguments: [
    (1, [AraPostNicknameType.regular]),
    (3, [.regular, .anonymous]),
    (4, [.realName]),
  ])
  func readsBoardFlags(flags: Int, expected: [AraPostNicknameType]) {
    #expect(AraPostNicknameType.allowed(byFlags: flags) == expected)
  }
}

@Suite("Ara market metadata")
struct AraMarketMetadataTests {
  private func decode(_ json: String) throws -> AraMarketListing? {
    try JSONDecoder().decode(AraMarketMetadataDTO.self, from: Data(json.utf8)).toModel()
  }

  @Test func decodesAListing() throws {
    let listing = try decode(#"{"price": 20000, "state": "soldout", "price_currency": "KRW"}"#)
    #expect(listing == AraMarketListing(price: 20000, currency: "KRW", state: .soldOut))
  }

  @Test func toleratesMissingAndOddPrices() throws {
    #expect(try decode(#"{"state": "onsale", "price_currency": "KRW"}"#)?.price == nil)
    #expect(try decode(#"{"price": "12,000"}"#)?.price == 12000)
    #expect(try decode(#"{"price": 9900.0}"#)?.price == 9900)
  }

  @Test func readsAFractionWrittenAsTextAsWholeWon() throws {
    #expect(try decode(#"{"price": "12000.50"}"#)?.price == 12000)
    #expect(try decode(#"{"price": "₩12,000"}"#)?.price == 12000)
  }

  @Test(arguments: [#"-5000"#, #""-5000""#])
  func dropsNegativePrices(value: String) throws {
    #expect(try decode(#"{"price": \#(value), "state": "onsale"}"#)?.price == nil)
  }

  @Test(arguments: ["[]", #""note""#, "3"])
  func ignoresMetadataThatIsntAnObject(json: String) throws {
    #expect(try decode(json) == nil)
  }

  @Test func decodesAPostWhoseMetadataIsntAnObject() throws {
    struct Post: Decodable { let metadata: AraMarketMetadataDTO? }
    let post = try JSONDecoder().decode(Post.self, from: Data(#"{"metadata": []}"#.utf8))
    #expect(post.metadata?.toModel() == nil)
  }

  /// Decoded for every post in a list, so a price no `Int` can hold mustn't crash the board.
  @Test(arguments: ["1e300", "-1e300", "9.3e18"])
  func dropsPricesTooLargeToHold(value: String) throws {
    #expect(try decode(#"{"price": \#(value), "state": "onsale"}"#)?.price == nil)
  }

  @Test func ignoresMetadataOfOtherBoards() throws {
    #expect(try decode(#"{"expire_at": "2026-11-01"}"#) == nil)
  }

  @Test func encodesWhatTheWebWrites() throws {
    let dto = AraMarketMetadataDTO.fromModel(AraMarketListing(price: 5000))
    let json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(dto)) as? [String: Any]
    #expect(json?["price"] as? Int == 5000)
    #expect(json?["price_currency"] as? String == "KRW")
    #expect(json?["state"] as? String == "onsale")
  }

  @Test func leavesMetadataOutOfAnUpdateWithoutAListing() throws {
    let request = AraPostUpdateRequestDTO.fromModel(
      AraUpdatePost(title: "t", content: "{}", attachmentIDs: [], isNSFW: false, isPolitical: false)
    )
    let json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(request)) as? [String: Any]
    #expect(json?.keys.contains("metadata") == false)
  }
}
