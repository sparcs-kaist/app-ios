//
//  SettingsViewModel.swift
//  soap
//
//  Created by 하정우 on 10/2/25.
//

import Foundation
import Factory
import BuddyDomain

@MainActor
@Observable
class SettingsViewModel {
  // MARK: - Dependencies
  @ObservationIgnored @Injected(\.authUseCase) private var authUseCase: AuthUseCaseProtocol
  
  func signOut() async throws {
    try await authUseCase.signOut()
  }
}
