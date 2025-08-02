//
//  SignInViewModel.swift
//  soap
//
//  Created by Soongyu Kwon on 30/05/2025.
//

import SwiftUI
import Observation
import Factory

@MainActor
@Observable
class SignInViewModel {
  var isLoading: Bool = false
  var errorMessage: String? = nil

  @ObservationIgnored @Injected(\.authUseCase) private var authUseCase: AuthUseCaseProtocol

  func signIn() async throws {
    isLoading = true
    defer { isLoading = false }

    try await authUseCase.signIn()
  }
}
