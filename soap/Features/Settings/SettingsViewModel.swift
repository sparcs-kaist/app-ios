//
//  SettingsViewModel.swift
//  soap
//
//  Created by 하정우 on 7/29/25.
//

import Foundation
import SwiftUI
import Factory
import Observation
import Moya

@MainActor
@Observable
class SettingsViewModel: SettingsViewModelProtocol {
  enum ViewState {
    case loading
    case loaded
  }
  enum SettingsError: Error {
    case araNicknameInterval
  }
  
  // MARK: - Mock data
  // TODO: implement API call & data structures
  var araAllowNSFWPosts: Bool = false
  var araAllowPoliticalPosts: Bool = false
  var araNickname: String = ""
  var taxiBankName: String?
  var taxiBankNumber: String = ""
  var otlMajor: String = "School of Computer Science"
  let otlMajorList: [String] = ["School of Computer Science", "School of Electrical Engineering", "School of Business"]
  
  // MARK: - Properties
  var araUser: AraMe?
  var taxiUser: TaxiUser?
  var taxiState: ViewState = .loading
  
  // MARK: - Dependencies
  @ObservationIgnored @Injected(\.userUseCase) private var userUseCase: UserUseCaseProtocol
  @ObservationIgnored @Injected(\.taxiUserRepository) private var taxiUserRepository: TaxiUserRepositoryProtocol
  
  // MARK: - Functions
  func fetchAraUser() async {
    self.araUser = await userUseCase.araUser
    araAllowNSFWPosts = araUser?.allowNSFW ?? false
    araAllowPoliticalPosts = araUser?.allowPolitical ?? false
    araNickname = araUser?.nickname ?? ""
  }
  
  func updateAraNickname() async throws {
    do {
      try await userUseCase.updateAraUser(params: ["nickname": araNickname])
    } catch {
      logger.debug("Failed to update ara nickname: \(error)")
      if let error = error as? MoyaError, error.response?.statusCode == 400 {
        throw SettingsError.araNicknameInterval
      }
    }
  }
  
  func updateAraPostVisibility() async {
    do {
      try await userUseCase.updateAraUser(params: ["see-sexual": araAllowNSFWPosts, "see-social": araAllowPoliticalPosts])
    } catch {
      logger.debug("Failed to update ara post visibility: \(error)")
    }
  }
  
  func fetchTaxiUser() async {
    await userUseCase.fetchUsers()
    self.taxiUser = await userUseCase.taxiUser
    taxiBankName = taxiUser?.account.split(separator: " ").first.map { String($0) }
    taxiBankNumber = String(taxiUser?.account.split(separator: " ").last ?? "")
    taxiState = .loaded
  }
  
  func taxiEditBankAccount(account: String) async {
    do {
      try await taxiUserRepository.editBankAccount(account: account)
    } catch {
      logger.debug("Failed to edit bank account: \(error.localizedDescription)")
    }
  }
}
