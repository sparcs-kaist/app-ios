//
//  NearbyBeaconUUIDTests.swift
//  BuddyDataTests
//
//  Created by Soongyu Kwon on 04/10/2026.
//

import Foundation
import Testing
@testable import BuddyDataCore

@Suite("Nearby beacon UUID")
struct NearbyBeaconUUIDTests {
  @Test func roundTrips() throws {
    let token = Data((0..<12).map { UInt8($0 * 17) })
    let string = try #require(NearbyBeaconUUID.string(for: token))
    #expect(string == "b0dd1e01-0011-2233-4455-66778899aabb")
    #expect(NearbyBeaconUUID.token(from: string) == token)
    #expect(NearbyBeaconUUID.token(from: string.uppercased()) == token)
  }

  @Test(arguments: [
    "0000180f-0000-1000-8000-00805f9b34fb",
    "b0dd1e02-0000-0000-0000-000000000000",
    "not-a-uuid",
    "180F"
  ])
  func rejectsOtherUUIDs(uuid: String) {
    #expect(NearbyBeaconUUID.token(from: uuid) == nil)
  }

  @Test func rejectsWrongTokenLength() {
    #expect(NearbyBeaconUUID.string(for: Data(count: 11)) == nil)
    #expect(NearbyBeaconUUID.string(for: Data(count: 13)) == nil)
  }
}
