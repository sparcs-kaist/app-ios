//
//  WebAuthenticating.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 28/03/2026.
//

import Foundation

public protocol WebAuthenticating: Sendable {
  func authenticate() async throws -> URL
}
