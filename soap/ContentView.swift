//
//  ContentView.swift
//  soap
//
//  Created by Soongyu Kwon on 30/10/2024.
//

import SwiftUI
import Combine
import Factory

struct ContentView: View {
  @Injected(\.authUseCase) private var authUseCase: AuthUseCaseProtocol
  @Injected(\.userUseCase) private var userUseCase: UserUseCaseProtocol
  @Bindable private var viewModel = ContentViewModel()

  var body: some View {
    ZStack {
      if viewModel.isAuthenticated {
        MainView()
          .transition(.opacity)
          .task {
            await userUseCase.fetchUsers()
          }
      } else if !viewModel.isLoading {
        SignInView()
          .transition(.opacity)
      }
    }
    .animation(.easeInOut(duration: 0.3), value: viewModel.isAuthenticated)
    .task {
      await viewModel.refreshAccessTokenIfNeeded()
    }
  }
}

#Preview {
  ContentView()
}


