//
//  TokenStoring.swift
//  BuddyCore
//
//  Created by Soongyu Kwon on 28/03/2026.
//

public protocol TokenStoring: Sendable {
  func save(_ tokenPair: TokenPair) throws
  func load() throws -> TokenPair?
  func clear() throws
}
