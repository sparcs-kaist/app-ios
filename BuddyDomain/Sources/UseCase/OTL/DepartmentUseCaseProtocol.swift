//
//  DepartmentUseCaseProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 14/03/2026.
//

import Foundation

public protocol DepartmentUseCaseProtocol {
  func getDepartments() async throws -> [Department]
}
