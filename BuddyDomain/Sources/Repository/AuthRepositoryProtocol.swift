//
//  AuthRepositoryProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 09/10/2025.
//

import Foundation

public protocol AuthRepositoryProtocol: Sendable {
  func requestToken(authorisationCode: String, codeVerifier: String) async throws -> SignInResponse
  func refreshToken(refreshToken: String) async throws -> TokenResponse
}
