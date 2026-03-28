//
//  ContentView.swift
//  soap
//
//  Created by Soongyu Kwon on 28/03/2026.
//

import SwiftUI
import BuddyFeatureAuth

struct ContentView: View {
  @Environment(AuthModel.self) private var authModel

  var body: some View {
    Group {
      if authModel.isBootstrapping {

      } else if authModel.isAuthenticated {
        Text("authenticated")
      } else {
        Button("Login") {
          Task {
            await authModel.login()
          }
        }
      }
    }
    .task {
      guard authModel.isBootstrapping else { return }
      await authModel.bootstrap()
    }
  }
}

#Preview {
  ContentView()
}
