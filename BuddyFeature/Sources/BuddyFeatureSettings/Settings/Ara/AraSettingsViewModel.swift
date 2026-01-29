//
//  AraSettingsViewModel.swift
//  soap
//
//  Created by 하정우 on 8/28/25.
//

import SwiftUI
import Combine
import Observation
import Factory
import BuddyDomain

@MainActor
protocol AraSettingsViewModelProtocol: Observable {
  var user: AraUser? { get }
  var allowNSFW: Bool { get set }
  var allowPolitical: Bool { get set }
  var nickname: String { get set }
  var nicknameUpdatable: Bool { get }
  var nicknameUpdatableFrom: Date? { get }
  var state: AraSettingsViewModel.ViewState { get }
  
  func fetchUser() async
  func updateNickname() async throws
  func updateContentPreference() async
}

@Observable
class AraSettingsViewModel: AraSettingsViewModelProtocol {
  enum ViewState: Equatable {
    case loading
    case loaded
    case error(message: String)
  }
  
  // MARK: - Dependencies
  @ObservationIgnored @Injected(\.userUseCase) private var userUseCase: UserUseCaseProtocol?

  // MARK: - Properties
  var user: AraUser?
  var allowNSFW: Bool = false
  var allowPolitical: Bool = false
  var nickname: String = ""
  var nicknameUpdatable: Bool {
    if let date = nicknameUpdatableFrom, date <= Date() {
      return true
    }
    return false
  }
  var nicknameUpdatableFrom: Date? {
    if let nicknameUpdatedAt = user?.nicknameUpdatedAt, let date = Calendar.current.date(byAdding: .month, value: 3, to: nicknameUpdatedAt) {
      return date
    }
    return nil
  }
  var state: ViewState = .loading
  
  // MARK: - Functions
  func fetchUser() async {
    guard let userUseCase else { return }

    state = .loading
    self.user = await userUseCase.araUser
    guard let user = self.user else {
      state = .error(message: "Ara User Information Not Found. ")
      return
    }
    allowNSFW = user.allowNSFW
    allowPolitical = user.allowPolitical
    nickname = user.nickname
    state = .loaded
  }
  
  func updateNickname() async throws {
    guard let userUseCase else { return }

    try await userUseCase.updateAraUser(params: ["nickname": nickname])
  }
  
  func updateContentPreference() async {
    guard let userUseCase else { return }
    
    do {
      try await userUseCase.updateAraUser(params: ["see_sexual": allowNSFW, "see_social": allowPolitical])
    } catch {
//      logger.error("Failed to update Ara content preference: \(error)")
    }
  }
}
