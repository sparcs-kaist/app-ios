//
//  TaxiSettingsViewModel.swift
//  soap
//
//  Created by 하정우 on 8/29/25.
//

import Foundation
import Factory

@MainActor
protocol TaxiSettingsViewModelProtocol: Observable {
  var taxiBankName: String? { get set }
  var taxiBankNumber: String { get set }
  var taxiUser: TaxiUser? { get }
  var state: TaxiSettingsViewModel.ViewState { get }
  
  func fetchTaxiUser() async
  func taxiEditBankAccount(account: String) async
}

@Observable
class TaxiSettingsViewModel: TaxiSettingsViewModelProtocol {
  enum ViewState {
    case loading
    case loaded
    case error(message: String)
  }
  
  // MARK: - Dependencies
  @ObservationIgnored @Injected(\.userUseCase) private var userUseCase: UserUseCaseProtocol
  @ObservationIgnored @Injected(\.taxiUserRepository) private var taxiUserRepository: TaxiUserRepositoryProtocol
  
  // MARK: - Properties
  var taxiBankName: String?
  var taxiBankNumber: String = ""
  var taxiUser: TaxiUser?
  var state: ViewState = .loading

  // MARK: - Functions
  func fetchTaxiUser() async {
    state = .loading
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
