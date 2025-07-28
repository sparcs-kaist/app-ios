//
//  TaxiChatPresignedURLDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 28/07/2025.
//

import Foundation

struct TaxiChatPresignedURLDTO: Codable {
  let id: String
  let url: String
  let fields: [String: String]
}
