//
//  TaxiReportType.swift
//  soap
//
//  Created by 하정우 on 9/10/25.
//

enum TaxiReportType: String, CaseIterable {
  case incoming = "Received"
  case outgoing = "Submitted"

  var description: String {
    switch self {
    case .incoming:
      String(localized: "Received")
    case .outgoing:
      String(localized: "Submitted")
    }
  }
}
