//
//  AuthUseCaseProtocol.swift
//  soap
//
//  Created by Soongyu Kwon on 09/07/2025.
//

import Foundation
import Combine

@MainActor
protocol AuthUseCaseProtocol {
  var isAuthenticatedPublisher: AnyPublisher<Bool, Never> { get }
  func signIn() async throws
  func signOut() async throws
  func getAccessToken() -> String?
  func getValidAccessToken() async throws -> String
  func refreshAccessTokenIfNeeded() async throws
}
