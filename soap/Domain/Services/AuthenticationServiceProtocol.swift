//
//  AuthenticationServiceProtocol.swift
//  soap
//
//  Created by Soongyu Kwon on 09/07/2025.
//

import Foundation

@MainActor
protocol AuthenticationServiceProtocol {
  func authenticate() async throws -> SignInResponseDTO
  func refreshAccessToken(refreshToken: String) async throws -> TokenResponseDTO
}
