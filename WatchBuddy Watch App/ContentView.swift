//
//  ContentView.swift
//  WatchBuddy Watch App
//
//  Created by Soongyu Kwon on 04/10/2025.
//

import SwiftUI
import Factory
import BuddyDomain

struct ContentView: View {
  @State private var viewModel = ContentViewModel()

  var body: some View {
    Group {
      if viewModel.isAuthenticated {
        Text("signed in")
      } else {
        Text("Please open Buddy on your iPhone to continue.")
          .multilineTextAlignment(.center)
      }
    }
    .onAppear {
      viewModel.bind()
    }
  }
}

#Preview {
  ContentView()
}

