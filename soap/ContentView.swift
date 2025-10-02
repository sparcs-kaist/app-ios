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

  var body: some View {
    ZStack {
      if viewModel.isAuthenticated {
        MainView()
      } else {
        SignInView()
      }
    }
    .transition(.opacity.animation(.easeInOut(duration: 0.3)))
    .onChange(of: scenePhase) {
      if scenePhase == .active {
        Task {
          await viewModel.refreshAccessTokenIfNeeded()
        }
      }
    }
  }
}

#Preview {
  ContentView()
}


