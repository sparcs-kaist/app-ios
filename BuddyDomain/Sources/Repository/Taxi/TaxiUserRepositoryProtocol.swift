//
//  TaxiUserRepositoryProtocol.swift
//  BuddyDomain
//
//  Created by Soongyu Kwon on 05/10/2025.
//

import Foundation

public protocol TaxiUserRepositoryProtocol: Sendable {
  func fetchUser() async throws -> TaxiUser
  func editBankAccount(account: String) async throws
}
