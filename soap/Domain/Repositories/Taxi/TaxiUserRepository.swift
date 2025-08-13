//
//  TaxiUserRepository.swift
//  soap
//
//  Created by Soongyu Kwon on 14/07/2025.
//

import Foundation

@preconcurrency
import Moya

protocol TaxiUserRepositoryProtocol: Sendable {
  func fetchUser() async throws -> TaxiUser
  func editBankAccount(account: String) async throws
  func fetchReports() async throws -> (reported: [TaxiReport], reporting: [TaxiReport])
}

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
  
  func fetchReports() async throws -> (reported: [TaxiReport], reporting: [TaxiReport]) {
    let response = try await provider.request(.fetchReports)
    let result = try response.map(TaxiReportDTO.self)
    
    var reported: [TaxiReport] = []
    var reporting: [TaxiReport] = []
    
    for report in result.reported {
      reported.append(report.toModel(type: .reported))
    }
    
    for report in result.reporting {
      reporting.append(report.toModel(type: .reporting))
    }
    
    return (reported: reported, reporting: reporting)
  }
}
