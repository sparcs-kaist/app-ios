//
//  TaxiReportDTO.swift
//  soap
//
//  Created by 하정우 on 8/12/25.
//

import Foundation

struct TaxiReportDTO: Decodable {
  struct ReportedID: Decodable {
    let nickname: String
    
    enum CodingKeys: String, CodingKey {
      case nickname
    }
  }
  
  struct TaxiReportDetail: Decodable {
    let id: String
    let reportedId: ReportedID
    let type: String
    let etcDetail: String
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
      case id = "_id"
      case reportedId
      case type
      case etcDetail
      case createdAt = "time"
    }
  }
  
  let reporting: [TaxiReportDetail]
  let reported: [TaxiReportDetail]
  
  enum CodingKeys: String, CodingKey {
    case reporting
    case reported
  }
}

extension TaxiReportDTO.TaxiReportDetail {
  func toModel(reportType: TaxiReport.ReportType) throws -> TaxiReport {
    TaxiReport(id: id, nickname: self.reportedId.nickname, reportType: reportType, reason: .init(rawValue: type)!, etcDetail: etcDetail, reportedAt: createdAt.toDate()!)
  }
}
