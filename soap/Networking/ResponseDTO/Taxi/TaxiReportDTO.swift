//
//  TaxiReportDTO.swift
//  soap
//
//  Created by 김민찬 on 8/11/25.
//

import Foundation
import BuddyDomain

struct TaxiReportedUserDTO: Codable {
  let id: String
  let oid: String
  let nickname: String
  let profileImageURL: String
  let withdraw: Bool
  
  enum CodingKeys: String, CodingKey {
    case id
    case oid = "_id"
    case nickname
    case profileImageURL = "profileImageUrl"
    case withdraw
  }
}

extension TaxiReportedUserDTO {
  func toModel() -> TaxiReportedUser {
    TaxiReportedUser(
      id: id,
      oid: oid,
      nickname: nickname,
      profileImageURL: URL(string: profileImageURL),
      withdraw: withdraw
    )
  }
}

struct TaxiReportDTO: Codable {
  let id: String
  let creatorID: String
  let reportedUser: TaxiReportedUserDTO
  let reason: String
  let etcDetails: String
  let time: String
  let roomID: String
  
  enum CodingKeys: String, CodingKey {
    case id = "_id"
    case creatorID = "creatorId"
    case reportedUser = "reportedId"
    case reason = "type"
    case etcDetails = "etcDetail"
    case time
    case roomID = "roomId"
  }
}

extension TaxiReportDTO {
  func toModel() -> TaxiReport {
    TaxiReport(
      id: id,
      creatorID: creatorID,
      reportedUser: reportedUser.toModel(),
      reason: TaxiReport.Reason(rawValue: reason) ?? .etcReason,
      etcDetails: etcDetails,
      time: time.toDate() ?? Date(),
      roomID: roomID
    )
  }
}
