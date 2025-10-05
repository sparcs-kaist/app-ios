//
//  AuthUseCaseProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 05/10/2025.
//

import Foundation
import Combine

@MainActor
public protocol AuthUseCaseProtocol {
  var isAuthenticatedPublisher: AnyPublisher<Bool, Never> { get }
  func signIn() async throws
  func signOut() async throws
  func getAccessToken() -> String?
  func getValidAccessToken() async throws -> String
  func refreshAccessTokenIfNeeded() async throws
}
