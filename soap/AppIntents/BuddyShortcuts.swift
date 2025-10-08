//
//  BuddyShortcuts.swift
//  soap
//
//  Created by Soongyu Kwon on 09/10/2025.
//

import AppIntents

struct BuddyShortcuts: AppShortcutsProvider {
  static let shortcutTileColor: ShortcutTileColor = .grape
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: NextClassAppIntents(),
      phrases: [
        "What is my next class in \(.applicationName)?",
        "What's the next class in \(.applicationName)?",
        "Next class in \(.applicationName)."
      ],
      shortTitle: "Next Class",
      systemImageName: "calendar.badge.clock"
    )
  }
}
