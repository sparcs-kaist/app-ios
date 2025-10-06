//
//  WatchBuddyApp.swift
//  WatchBuddy Watch App
//
//  Created by Soongyu Kwon on 04/10/2025.
//

import SwiftUI
import BuddyDomain
import Factory

@main
struct WatchBuddy_Watch_AppApp: App {
  @Injected(
    \.tokenBridgeServiceWatch
  ) private var tokenBridgeServiceWatch: TokenBridgeServiceWatchProtocol

  init() {
    // watchOS support
    tokenBridgeServiceWatch.start()
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}

