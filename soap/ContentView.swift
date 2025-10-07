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
  @Bindable private var viewModel = ContentViewModel()
  @Environment(\.scenePhase) private var scenePhase
  @InjectedObservable(\.crashlyticsHelper) private var crashlyticsHelper

  var body: some View {
    ZStack {
      if viewModel.isAuthenticated {
        MainView()
      } else if viewModel.isLoading {
        // MARK: THIS PLAYS CRUCIAL ROLE HIDING SIGN IN VIEW ON LOADING
      } else {
        SignInView()
      }
    }
    .task {
      await viewModel.refreshAccessTokenIfNeeded()
    }
    .transition(.opacity.animation(.easeInOut(duration: 0.3)))
    .onChange(of: scenePhase) {
      if scenePhase == .active {
        Task {
          await viewModel.refreshAccessTokenIfNeeded()
        }
      }
    }
    .alert("Error", isPresented: $crashlyticsHelper.showAlert, actions: {
      Button(role: .confirm) { }
    }, message: {
      Text("Something went wrong. Please try again later.")
    })
  }
}

#Preview {
  ContentView()
}


