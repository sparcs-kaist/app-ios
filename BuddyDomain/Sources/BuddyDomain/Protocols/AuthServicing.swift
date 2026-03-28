//
//  AuthServicing.swift
//  BuddyCore
//
//  Created by Soongyu Kwon on 28/03/2026.
//

import Foundation

public protocol AuthServicing: Sendable {
  func bootstrap() async -> Bool
  func login() async throws
  func validAccessToken() async throws -> String
  func logout() async
}
