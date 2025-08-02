//
//  TaxiUserRepositoryProtocol.swift
//  soap
//
//  Created by Soongyu Kwon on 14/07/2025.
//

import Foundation

protocol TaxiUserRepositoryProtocol: Sendable {
  func fetchUser() async throws -> TaxiUser
}
