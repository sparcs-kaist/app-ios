//
//  OTLDepartmentRepositoryProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 14/03/2026.
//

import Foundation

public protocol OTLDepartmentRepositoryProtocol: Sendable {
  func getDepartments() async throws -> [Department]
}
