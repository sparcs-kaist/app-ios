//
//  TokenExchangeResponseDTO.swift
//  BuddyCore
//
//  Created by Soongyu Kwon on 28/03/2026.
//

import Foundation

public struct TokenExchangeResponseDTO: Codable, Sendable {
  public let accessToken: String
  public let refreshToken: String
  public let ssoInf: String

  public init(accessToken: String, refreshToken: String, ssoInf: String) {
    self.accessToken = accessToken
    self.refreshToken = refreshToken
    self.ssoInf = ssoInf
  }
}
