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

@MainActor
protocol AraSettingsViewModelProtocol: Observable {
  var araUser: AraMe? { get }
  var araAllowNSFWPosts: Bool { get set }
  var araAllowPoliticalPosts: Bool { get set }
  var araNickname: String { get set }
  var araNicknameUpdatable: Bool { get }
  var araNicknameUpdatableSince: Date? { get }
  var state: AraSettingsViewModel.ViewState { get }
  
  func fetchAraUser() async
  func updateAraNickname() async throws
  func updateAraContentPreference() async
}

@Observable
class AraSettingsViewModel: AraSettingsViewModelProtocol {
  enum ViewState: Equatable {
    case loading
    case loaded
    case error(message: String)
  }
  
  // MARK: - Dependencies
  @ObservationIgnored @Injected(\.userUseCase) private var userUseCase: UserUseCaseProtocol
  @ObservationIgnored @Injected(\.araBoardRepository) private var araBoardRepository: AraBoardRepositoryProtocol

  // MARK: - Properties
  var araUser: AraMe?
  var araAllowNSFWPosts: Bool = false
  var araAllowPoliticalPosts: Bool = false
  var araNickname: String = ""
  var araNicknameUpdatable: Bool {
    if let date = araNicknameUpdatableSince, date <= Date() {
      return true
    }
    return false
  }
  var araNicknameUpdatableSince: Date? {
    if let nicknameUpdatedAt = araUser?.nicknameUpdatedAt, let date = Calendar.current.date(byAdding: .month, value: 3, to: nicknameUpdatedAt) {
      return date
    }
    return nil
  }
  var state: ViewState = .loading
  
  // MARK: - Functions
  func fetchAraUser() async {
    state = .loading
    self.araUser = await userUseCase.araUser
    guard let user = self.araUser else {
      state = .error(message: "Ara User Information Not Found. ")
      return
    }
    araAllowNSFWPosts = user.allowNSFW
    araAllowPoliticalPosts = user.allowPolitical
    araNickname = user.nickname
    state = .loaded
  }
  
  func updateAraNickname() async throws {
    try await userUseCase.updateAraUser(params: ["nickname": araNickname])
  }
  
  func updateAraContentPreference() async {
    do {
      try await userUseCase.updateAraUser(params: ["see_sexual": araAllowNSFWPosts, "see_social": araAllowPoliticalPosts])
    } catch {
      logger.error("Failed to update Ara content preference: \(error)")
    }
  }
}
