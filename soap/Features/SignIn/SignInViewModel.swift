//
//  SignInViewModel.swift
//  soap
//
//  Created by Soongyu Kwon on 30/05/2025.
//

import SwiftUI
import Observation
import Factory
import BuddyDomain

@MainActor
@Observable
class SignInViewModel {
  var isLoading: Bool = false
  var errorMessage: String? = nil

  @ObservationIgnored @Injected(\.authUseCase) private var authUseCase: AuthUseCaseProtocol?
  @ObservationIgnored @Injected(\.userUseCase) private var userUseCase: UserUseCaseProtocol?

  func signIn() async throws {
    guard let authUseCase, let userUseCase else { return }
    
    isLoading = true
    defer { isLoading = false }

    do {
      try await authUseCase.signIn()
    } catch let error as AuthUseCaseError where error.isUserCancellation {
      return // The user closed the SSO sheet; leave them on the sign-in screen without an alert.
    }
    await userUseCase.fetchUsers()
  }
}
