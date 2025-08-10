//
//  TaxiMyReportsResponseDTO.swift
//  soap
//
//  Created by 김민찬 on 8/11/25.
//

import Foundation

struct TaxiMyReportsResponseDTO: Codable {
  let incoming: [TaxiReportDTO]
  let outgoing: [TaxiReportDTO]
  
  enum CodingKeys: String, CodingKey {
    case incoming = "reported"
    case outgoing = "reporting"
  }
}
