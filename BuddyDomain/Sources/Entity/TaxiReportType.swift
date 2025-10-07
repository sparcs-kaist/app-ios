//
//  TaxiReportType.swift
//  soap
//
//  Created by 하정우 on 9/10/25.
//

public enum TaxiReportType: String, CaseIterable {
  case incoming = "Received"
  case outgoing = "Submitted"

  public var description: String {
    switch self {
    case .incoming:
      String(localized: "Received", bundle: .module)
    case .outgoing:
      String(localized: "Submitted", bundle: .module)
    }
  }
}
