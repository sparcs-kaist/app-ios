//
//  ThemeActionsTip.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 19/10/2026.
//

import SwiftUI
import TipKit

/// Above the themes, on a second visit: their actions are behind a long press and a swipe.
struct ThemeActionsTip: Tip {
  static let screenVisited = Tips.Event(id: "timetableTheme.visited")

  var title: Text { Text("Share and Edit Themes", bundle: .module) }
  var message: Text? { Text("Touch and hold a theme to share or duplicate it, or swipe one of yours to edit it.", bundle: .module) }
  var image: Image? { Image(systemName: "paintpalette") }
  var rules: [Rule] {
    [#Rule(Self.screenVisited) { $0.donations.count >= 2 }]
  }
  var options: [any TipOption] { [Tips.MaxDisplayCount(3)] }
}
