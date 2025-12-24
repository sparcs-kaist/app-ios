//
//  TaxiSettingsViewModel.swift
//  soap
//
//  Created by 하정우 on 8/29/25.
//

import Foundation
import Factory
import BuddyDomain

@MainActor
protocol TaxiSettingsViewModelProtocol: Observable {
  var bankName: String? { get set }
  var bankNumber: String { get set }
  var phoneNumber: String { get set }
  var showBadge: Bool { get set }
  var user: TaxiUser? { get }
  var state: TaxiSettingsViewModel.ViewState { get }
  
  func fetchUser() async
  func editInformation() async
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
  @ObservationIgnored @Injected(\.crashlyticsHelper) private var crashlyticsHelper: CrashlyticsHelper
  
  // MARK: - Properties
  var bankName: String?
  var bankNumber: String = ""
  var phoneNumber: String = ""
  var showBadge: Bool = false
  var user: TaxiUser?
  var state: ViewState = .loading

  // MARK: - Functions
  func fetchUser() async {
    state = .loading
    self.user = await userUseCase.taxiUser
    guard let user = self.user else {
      state = .error(message: "Taxi User Information Not Found.")
      return
    }
    bankName = user.account.split(separator: " ").first.map { String($0) }
    bankNumber = String(user.account.split(separator: " ").last ?? "")
    phoneNumber = user.phoneNumber ?? ""
    showBadge = user.badge ?? false
    state = .loaded
  }
  
  func editInformation() async {
    do {
      if let bankName, !bankNumber.isEmpty {
        try await taxiUserRepository.editBankAccount(account: "\(bankName) \(bankNumber)")
      }
      if !phoneNumber.isEmpty && user?.phoneNumber != phoneNumber {
        try await taxiUserRepository.registerPhoneNumber(phoneNumber: phoneNumber)
      }
      if user?.badge != showBadge {
        try await taxiUserRepository.editBadge(showBadge: showBadge)
      }
      try await userUseCase.fetchTaxiUser()
    } catch {
      logger.debug("Failed to edit user information: \(error.localizedDescription)")
      crashlyticsHelper.recordException(error: error)
    }
  }
}
