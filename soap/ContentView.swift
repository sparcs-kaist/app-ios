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
  @Injected(\.crashlyticsHelper) private var crashlyticsHelper

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
      await viewModel.onActivation()
    }
    .transition(.opacity.animation(.easeInOut(duration: 0.3)))
    .onChange(of: scenePhase) {
      if scenePhase == .active {
        Task {
          await viewModel.onActivation()
        }
      }
    }
    .alert("Update Required", isPresented: $viewModel.isUpdateRequired, actions: {
      Button(action: {
        viewModel.resetTimer()
        UIApplication.shared.open(Constants.appStoreURL, options: [:], completionHandler: nil)
      }, label: {
        Text("Open App Store")
      })
    }, message: {
      Text("A new version is available. Please update to continue.")
    })
  }
}

#Preview {
  ContentView()
}


