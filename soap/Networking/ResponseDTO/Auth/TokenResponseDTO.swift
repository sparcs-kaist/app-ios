//
//  TokenResponseDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 09/07/2025.
//

import Foundation

struct TokenResponseDTO: Codable {
  let accessToken: String
  let refreshToken: String
}
