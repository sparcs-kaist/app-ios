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
  var state: ViewState = .loading
  
  // MARK: - Dependencies
  @ObservationIgnored @Injected(\.userUseCase) private var userUseCase: UserUseCaseProtocol
  @ObservationIgnored @Injected(\.taxiUserRepository) private var taxiUserRepository: TaxiUserRepositoryProtocol
  
  // MARK: - Functions
  func fetchAraUser() async {
    state = .loading
    self.araUser = await userUseCase.araUser
    araAllowNSFWPosts = araUser?.allowNSFW ?? false
    araAllowPoliticalPosts = araUser?.allowPolitical ?? false
    araNickname = araUser?.nickname ?? ""
    state = .loaded
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
      try await userUseCase.updateAraUser(params: ["see_sexual": araAllowNSFWPosts, "see_social": araAllowPoliticalPosts])
    } catch {
      logger.debug("Failed to update ara post visibility: \(error)")
    }
  }
  
  func fetchTaxiUser() async {
    state = .loading
    await userUseCase.fetchUsers()
    self.taxiUser = await userUseCase.taxiUser
    taxiBankName = taxiUser?.account.split(separator: " ").first.map { String($0) }
    taxiBankNumber = String(taxiUser?.account.split(separator: " ").last ?? "")
    state = .loaded
  }
  
  func taxiEditBankAccount(account: String) async {
    do {
      try await taxiUserRepository.editBankAccount(account: account)
    } catch {
      logger.debug("Failed to edit bank account: \(error.localizedDescription)")
    }
  }
}
