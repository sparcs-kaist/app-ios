//
//  TokenResponseDTO.swift
//  soap
//
//  Created by Soongyu Kwon on 09/07/2025.
//

import Foundation
import BuddyDomain

public struct TokenResponseDTO: Codable {
  let accessToken: String
  let refreshToken: String
}

public extension TokenResponseDTO {
  func toModel() -> TokenResponse {
    TokenResponse(accessToken: accessToken, refreshToken: refreshToken)
  }
}
