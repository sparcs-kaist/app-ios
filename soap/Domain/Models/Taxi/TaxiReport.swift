//
//  TaxiReport.swift
//  soap
//
//  Created by 하정우 on 8/12/25.
//

import Foundation

public struct TaxiReport: Identifiable {
  enum ReportType: String, CaseIterable {
    case reported = "Received"
    case reporting = "Submitted"
  }
  
  enum ReportReason: String {
    case noSettlement = "no-settlement"
    case noShow = "no-show"
    case etc = "etc-reason"
  }
  
  public let id: String
  let nickname: String?
  let reportType: ReportType
  let reason: ReportReason
  let etcDetail: String
  let reportedAt: Date
}
