//
//  AuthRepositoryProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 09/10/2025.
//

import Foundation

public protocol AuthRepositoryProtocol: Sendable {
  func requestToken(session: String, codeVerifier: String) async throws -> SignInResponse
  func refreshToken(refreshToken: String) async throws -> TokenResponse
  func logout(refreshToken: String) async throws
}
