//
//  ContentViewModel.swift
//  soap
//
//  Created by Soongyu Kwon on 09/07/2025.
//

import SwiftUI
import Combine
import Observation
import Factory
import BuddyDomain

@Observable
@MainActor
class ContentViewModel {
  var isLoading = true
  var isAuthenticated = false
  var isUpdateRequired = false
  private var cancellables = Set<AnyCancellable>()
  private var lastCheckTime: Date?

  @ObservationIgnored @Injected(\.authUseCase) private var authUseCase: AuthUseCaseProtocol
  @ObservationIgnored @Injected(\.userUseCase) private var userUseCase: UserUseCaseProtocol
  @ObservationIgnored @Injected(\.taxiLocationUseCase) private var taxiLocationUseCase: TaxiLocationUseCaseProtocol
  @ObservationIgnored @Injected(\.versionRepository) private var versionRepository: VersionRepositoryProtocol

  init() {
    authUseCase.isAuthenticatedPublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] newValue in
        guard let self = self else { return }
        self.isAuthenticated = newValue
        isLoading = false
      }
      .store(in: &cancellables)
  }
  
  func onActivation() async {
    isLoading = true
    
    await checkUpdateIfNeeded()
    if isUpdateRequired { return }
    await refreshAccessTokenIfNeeded()
    
    isLoading = false
  }

  func refreshAccessTokenIfNeeded() async {
    do {
      // Avoid forcing refresh when token is still valid
      try await authUseCase.refreshAccessToken(force: false)
      await userUseCase.fetchUsers()
    } catch {
      logger.error(error)
    }
  }
  
  func fetchTaxiLocations() async {
    do {
      try await taxiLocationUseCase.fetchLocations()
    } catch {
      logger.error(error)
    }
  }
  
  func checkUpdateIfNeeded() async {
    let now = Date()
    
    if lastCheckTime == nil || now.timeIntervalSince(lastCheckTime!) > 3600 { // 1 hour interval
      await checkForUpdates()
      lastCheckTime = now
    }
  }
  
  func resetTimer() {
    lastCheckTime = nil
  }
  
  private func checkForUpdates() async  {
    logger.debug("Checking for updates")
    guard let requiredVersion = try? await versionRepository.getMinimumVersion() else {
      logger.error("Failed to fetch minimum required version.")
      isUpdateRequired = false // TODO: check if network connection is lost
      return
    }
    
    guard let currentVersion = getAppVersion() else {
      logger.error("Failed to get current app version.")
      isUpdateRequired = false
      return
    }
    
    isUpdateRequired = currentVersion.compare(requiredVersion, options: .numeric) == .orderedAscending
  }
  
  private func getAppVersion() -> String? {
    if let info = Bundle.main.infoDictionary, let currentVersion = info["CFBundleShortVersionString"] as? String {
      return currentVersion
    }
    return nil
  }
}
