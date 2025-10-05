//
//  TaxiCreateReportRequestDTO.swift
//  soap
//
//  Created by 김민찬 on 8/11/25.
//

import Foundation
import BuddyDomain

struct TaxiCreateReportRequestDTO: Codable {
  var reportedId: String
  var type: String
  var etcDetail: String?
  var time: String
  var roomId: String
}

extension TaxiCreateReportRequestDTO {
  static func fromModel(_ model: TaxiCreateReport) -> TaxiCreateReportRequestDTO {
    TaxiCreateReportRequestDTO(
      reportedId: model.reportedID,
      type: model.reason.rawValue,
      etcDetail: model.etcDetails,
      time: model.time.toISO8601,
      roomId: model.roomID
    )
  }
}
