//
//  OTLUserDTOTests.swift
//  BuddyDataTests
//
//  Created by Soongyu Kwon on 04/10/2026.
//

import Foundation
import Testing
import BuddyDomain
@testable import BuddyDataCore

@Suite("OTL user decoding")
struct OTLUserDTOTests {
  @Test func nullDegreeStillDecodes() throws {
    let json = #"{"id":1,"name":"홍길동","mail":"a@kaist.ac.kr","studentNumber":20230001,"degree":null,"majorDepartments":[{"id":3,"name":"전산학부","code":"CS"}],"interestedDepartments":[]}"#
    let user = try JSONDecoder().decode(OTLUserDTO.self, from: Data(json.utf8)).toModel()
    #expect(user.name == "홍길동")
    #expect(user.degree == nil)
    #expect(user.email == "a@kaist.ac.kr")
  }

  @Test func missingDepartmentListsDecodeAsEmpty() throws {
    let json = #"{"id":1,"name":"홍길동","mail":"a@kaist.ac.kr","studentNumber":20230001,"degree":"학사"}"#
    let user = try JSONDecoder().decode(OTLUserDTO.self, from: Data(json.utf8)).toModel()
    #expect(user.degree == "학사")
    #expect(user.majorDepartments.isEmpty)
    #expect(user.interestedDepartments.isEmpty)
  }
}
