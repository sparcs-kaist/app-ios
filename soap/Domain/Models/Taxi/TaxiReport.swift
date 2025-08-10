//
//  TaxiReport.swift
//  soap
//
//  Created by 김민찬 on 8/11/25.
//

import Foundation

struct TaxiReport: Identifiable, Hashable {
  enum Reason: String {
    case noSettlement = "no-settlement"
    case noShow = "no-show"
    case etcReason = "etc-reason"
  }
  
  let id: String
  let creatorID: String
  let reportedID: String
  let reason: Reason
  let etcDetail: String?
  let time: Date
  let roomID: String?
}
