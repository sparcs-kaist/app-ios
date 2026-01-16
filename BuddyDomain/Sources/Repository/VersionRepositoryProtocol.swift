//
//  VersionRepositoryProtocol.swift
//  BuddyDomain
//
//  Created by 하정우 on 1/16/26.
//

import Foundation

public protocol VersionRepositoryProtocol: Sendable {
  func getMinimumVersion() async throws -> String
}
