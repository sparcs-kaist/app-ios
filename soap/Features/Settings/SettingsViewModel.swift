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
    case error(message: String)
  }
  
  // MARK: - Properties
  var taxiBankName: String?
  var taxiBankNumber: String = ""
  var otlMajor: String = "School of Computer Science"
  let otlMajorList: [String] = ["School of Computer Science", "School of Electrical Engineering", "School of Business"]
  var taxiUser: TaxiUser?
  var state: ViewState = .loading
  
  // MARK: - Dependencies
  @ObservationIgnored @Injected(\.userUseCase) private var userUseCase: UserUseCaseProtocol
  @ObservationIgnored @Injected(\.taxiUserRepository) private var taxiUserRepository: TaxiUserRepositoryProtocol
  
  // MARK: - Functions
  func fetchTaxiUser() async {
    state = .loading
    do {
      try await userUseCase.fetchTaxiUser()
    } catch {
      state = .error(message: error.localizedDescription)
    }
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
