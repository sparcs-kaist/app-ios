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
  var showAlert: Bool { get set }
  var alertContent: LocalizedStringResource { get set }
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
    case error(message: LocalizedStringResource)
  }
  
  enum ErrorType {
    case fetch
    case bank
    case badge
    case phone
  }
  
  // MARK: - Dependencies
  @ObservationIgnored @Injected(\.userUseCase) private var userUseCase: UserUseCaseProtocol
  @ObservationIgnored @Injected(\.taxiUserRepository) private var taxiUserRepository: TaxiUserRepositoryProtocol?
  @ObservationIgnored @Injected(\.crashlyticsService) private var crashlyticsService: CrashlyticsServiceProtocol
  
  // MARK: - Properties
  var bankName: String?
  var bankNumber: String = ""
  var phoneNumber: String = ""
  var showBadge: Bool = false
  var showAlert: Bool = false
  var alertContent: LocalizedStringResource = ""
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
    phoneNumber = (user.phoneNumber ?? "").filter { $0.isASCIINumber }
    showBadge = user.badge ?? false
    state = .loaded
  }
  
  func editInformation() async {
    if let bankName, !bankNumber.isEmpty {
      await editBankAccount(bankName: bankName, bankNumber: bankNumber)
    }
    if !phoneNumber.isEmpty && user?.phoneNumber != phoneNumber.formatPhoneNumber() {
      await registerPhoneNumber(phoneNumber: phoneNumber.formatPhoneNumber())
    }
    if user?.badge != showBadge {
      await editBadge(showBadge: showBadge)
    }
    do {
      try await userUseCase.fetchTaxiUser()
    } catch {
      logger.debug("Failed to fetch user information: \(error.localizedDescription)")
      handleException(error: error, type: .fetch)
    }
  }
  
  private func editBankAccount(bankName: String, bankNumber: String) async {
    guard let taxiUserRepository else { return }

    do {
      try await taxiUserRepository.editBankAccount(account: "\(bankName) \(bankNumber)")
    } catch {
      logger.debug("Failed to edit bank account: \(error.localizedDescription)")
      handleException(error: error, type: .bank)
    }
  }
  
  private func registerPhoneNumber(phoneNumber: String) async {
    guard let taxiUserRepository else { return }

    do {
      try await taxiUserRepository.registerPhoneNumber(phoneNumber: phoneNumber)
    } catch {
      logger.debug("Failed to register phone number: \(error.localizedDescription)")
      handleException(error: error, type: .phone)
    }
  }
  
  private func editBadge(showBadge: Bool) async {
    guard let taxiUserRepository else { return }
    
    do {
      try await taxiUserRepository.editBadge(showBadge: showBadge)
    } catch {
      logger.debug("Failed to edit badge: \(error.localizedDescription)")
      handleException(error: error, type: .badge)
    }
  }
  
  private func handleException(error: Error, type: ErrorType) {
    if error.isNetworkMoyaError {
      alertContent = "You are not connected to the Internet."
    } else {
      alertContent = {
        switch type {
        case .badge:
          return "An unexpected error occurred while updating badge information. Please try again later."
        case .bank:
          return "An unexpected error occurred while updating bank account information. Please try again later."
        case .phone:
          return "An unexpected error occurred while updating phone number information. Please try again later."
        case .fetch:
          return "An unexpected error occurred while fetching user information. Please try again later."
        }
      }()
      crashlyticsService.recordException(error: error)
    }
    
    if type == .fetch {
      state = .error(message: alertContent)
      return
    }
    
    showAlert = true
  }
}
