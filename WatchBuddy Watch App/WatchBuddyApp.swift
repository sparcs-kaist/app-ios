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
    \.sessionBridgeServiceWatch
  ) private var sessionBridgeServiceWatch: SessionBridgeServiceWatchProtocol

  init() {
    // watchOS support
    sessionBridgeServiceWatch.start()
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}

