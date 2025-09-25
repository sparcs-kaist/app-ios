//
//  TaxiCreateReport.swift
//  soap
//
//  Created by 김민찬 on 8/11/25.
//

import Foundation

struct TaxiCreateReport {
  var reportedID: String
  var reason: TaxiReport.Reason
  var etcDetails: String?
  var time: Date
  var roomID: String
}
