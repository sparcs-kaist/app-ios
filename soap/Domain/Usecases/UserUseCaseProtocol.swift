//
//  UserUseCaseProtocol.swift
//  soap
//
//  Created by Soongyu Kwon on 14/07/2025.
//

import Foundation

@MainActor
protocol UserUseCaseProtocol {
  var taxiUser: TaxiUser? { get }

  func fetchUsers() async
  func fetchTaxiUser() async throws
}
