//
//  TaxiReport.swift
//  soap
//
//  Created by 김민찬 on 8/11/25.
//

import Foundation

struct TaxiReportedUser: Identifiable, Hashable {
  let id: String
  let oid: String
  let nickname: String
  let profileImageURL: URL?
  let withdraw: Bool
}

struct TaxiReport: Identifiable, Hashable {
  enum Reason: String {
    case noSettlement = "no-settlement"
    case noShow = "no-show"
    case etcReason = "etc-reason"
  }
  
  let id: String
  let creatorID: String
  let reportedUser: TaxiReportedUser
  let reason: Reason
  let etcDetails: String
  let time: Date
  let roomID: String?
}
