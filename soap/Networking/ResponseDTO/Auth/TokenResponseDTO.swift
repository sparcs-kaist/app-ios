//
//  TokenResponseDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 09/07/2025.
//

import Foundation
import BuddyDomain

struct TokenResponseDTO: Codable {
  let accessToken: String
  let refreshToken: String
}

extension TokenResponseDTO {
  func toModel() -> TokenResponse {
    TokenResponse(accessToken: accessToken, refreshToken: refreshToken)
  }
}
