//
//  TaxiReport.swift
//  soap
//
//  Created by 김민찬 on 8/11/25.
//

import Foundation

public struct TaxiReportedUser: Identifiable, Hashable {
  public let id: String
  public let oid: String
  public let nickname: String
  public let profileImageURL: URL?
  public let withdraw: Bool

  public init(id: String, oid: String, nickname: String, profileImageURL: URL?, withdraw: Bool) {
    self.id = id
    self.oid = oid
    self.nickname = nickname
    self.profileImageURL = profileImageURL
    self.withdraw = withdraw
  }
}

public struct TaxiReport: Identifiable, Hashable {
  public enum Reason: String {
    case noSettlement = "no-settlement"
    case noShow = "no-show"
    case etcReason = "etc-reason"
  }
  
  public let id: String
  public let creatorID: String
  public let reportedUser: TaxiReportedUser
  public let reason: Reason
  public let etcDetails: String
  public let time: Date
  public let roomID: String?

  public init(
    id: String,
    creatorID: String,
    reportedUser: TaxiReportedUser,
    reason: Reason,
    etcDetails: String,
    time: Date,
    roomID: String?
  ) {
    self.id = id
    self.creatorID = creatorID
    self.reportedUser = reportedUser
    self.reason = reason
    self.etcDetails = etcDetails
    self.time = time
    self.roomID = roomID
  }
}
