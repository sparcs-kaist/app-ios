//
//  AuthenticationServiceProtocol.swift
//  soap
//
//  Created by Soongyu Kwon on 09/07/2025.
//

import Foundation

@MainActor
public protocol AuthenticationServiceProtocol: Sendable {
  func authenticate() async throws -> SignInResponse
  func refreshAccessToken(refreshToken: String) async throws -> TokenResponse
}
