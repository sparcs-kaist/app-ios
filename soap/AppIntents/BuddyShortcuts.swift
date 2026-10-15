//
//  BuddyShortcuts.swift
//  soap
//
//  Created by Soongyu Kwon on 10/10/2025.
//

import AppIntents
import BuddyIntents

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
    AppShortcut(
      intent: MyLecturesIntent(),
      phrases: [
        "What are my lectures in \(.applicationName)?",
        "What classes am I taking this semester in \(.applicationName)?",
        "My lectures in \(.applicationName)."
      ],
      shortTitle: "My Lectures",
      systemImageName: "books.vertical"
    )
  }
}
