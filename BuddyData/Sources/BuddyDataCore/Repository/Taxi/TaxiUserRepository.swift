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

public enum TaxiUserErrorCode: Int {
  case editBankAccountFailed = 2001
  case editBadgeFailed = 2002
  case registerPhoneNumberFailed = 2003
}

public final class TaxiUserRepository: TaxiUserRepositoryProtocol, Sendable {
  private let provider: MoyaProvider<TaxiUserTarget>

  public init(provider: MoyaProvider<TaxiUserTarget>) {
    self.provider = provider
  }

  public func fetchUser() async throws -> TaxiUser {
    let response = try await provider.request(.fetchUserInfo)
    let result = try response.map(TaxiUserDTO.self).toModel()

    return result
  }
  
  public func editBadge(showBadge: Bool) async throws {
    let response = try await provider.request(.editBadge(badge: showBadge))
    
    if response.statusCode != 200 {
      throw NSError(
        domain: "TaxiUserRepository",
        code: TaxiUserErrorCode.editBadgeFailed.rawValue,
        userInfo: [NSLocalizedDescriptionKey : "Failed to edit badge option"]
      )
    }
  }
  
  public func editBankAccount(account: String) async throws {
    let response = try await provider.request(.editBankAccount(account: account))
    
    if response.statusCode != 200 {
      throw NSError(
        domain: "TaxiUserRepository",
        code: TaxiUserErrorCode.editBankAccountFailed.rawValue,
        userInfo: [NSLocalizedDescriptionKey : "Failed to edit bank account"]
      )
    }
  }
  
  public func registerPhoneNumber(phoneNumber: String) async throws {
    let response = try await provider.request(.registerPhoneNumber(phoneNumber: phoneNumber))
    
    if response.statusCode != 200 {
      throw NSError(
        domain: "TaxiUserRepository",
        code: TaxiUserErrorCode.registerPhoneNumberFailed.rawValue,
        userInfo: [NSLocalizedDescriptionKey : "Failed to register phone number"]
      )
    }
  }
}
