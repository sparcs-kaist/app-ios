//
//  TokenStorageProtocol.swift
//  soap
//
//  Created by Soongyu Kwon on 09/07/2025.
//

import Foundation

protocol TokenStorageProtocol {
  func save(accessToken: String, refreshToken: String)
  func getAccessToken() -> String?
  func getRefreshToken() -> String?
  func clearTokens()
}
