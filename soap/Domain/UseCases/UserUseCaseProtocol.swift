//
//  UserUseCaseProtocol.swift
//  soap
//
//  Created by Soongyu Kwon on 14/07/2025.
//

import Foundation

protocol UserUseCaseProtocol: Sendable {
  var taxiUser: TaxiUser? { get async }

  func fetchUsers() async
  func fetchTaxiUser() async throws
  func taxiEditAccount(account: String) async
  func fetchTaxiReports() async throws -> (reported: [TaxiReport], reporting: [TaxiReport])
}
