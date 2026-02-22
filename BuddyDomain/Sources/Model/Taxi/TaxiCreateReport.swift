//
//  TaxiCreateReport.swift
//  soap
//
//  Created by 김민찬 on 8/11/25.
//

import Foundation

public struct TaxiCreateReport: Sendable {
  public var reportedID: String
  public var reason: TaxiReport.Reason
  public var etcDetails: String?
  public var time: Date
  public var roomID: String

  public init(
    reportedID: String,
    reason: TaxiReport.Reason,
    etcDetails: String? = nil,
    time: Date,
    roomID: String
  ) {
    self.reportedID = reportedID
    self.reason = reason
    self.etcDetails = etcDetails
    self.time = time
    self.roomID = roomID
  }
}
