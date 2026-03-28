//
//  soapApp.swift
//  soap
//
//  Created by Soongyu Kwon on 28/03/2026.
//

import SwiftUI
import BuddyFeatureAuth

@main
struct soapApp: App {
  @State private var authModel = AuthModel()

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environment(authModel)
    }
  }
}

