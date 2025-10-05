//
//  TaxiUserRepository.swift
//  soap
//
//  Created by Soongyu Kwon on 14/07/2025.
//

import Foundation
import BuddyDomain

@preconcurrency
import Moya

enum TaxiUserErrorCode: Int {
  case editBankAccountFailed = 2001
}

final class TaxiUserRepository: TaxiUserRepositoryProtocol, Sendable {
  private let provider: MoyaProvider<TaxiUserTarget>

  init(provider: MoyaProvider<TaxiUserTarget>) {
    self.provider = provider
  }

  func fetchUser() async throws -> TaxiUser {
    let response = try await provider.request(.fetchUserInfo)
    let result = try response.map(TaxiUserDTO.self).toModel()

    return result
  }
  
  func editBankAccount(account: String) async throws {
    let response = try await provider.request(.editBankAccount(account: account))
    
    if response.statusCode != 200 {
      throw NSError(
        domain: "TaxiUserRepository",
        code: TaxiUserErrorCode.editBankAccountFailed.rawValue,
        userInfo: [NSLocalizedDescriptionKey : "Failed to edit bank account"]
      )
    }
  }
}
