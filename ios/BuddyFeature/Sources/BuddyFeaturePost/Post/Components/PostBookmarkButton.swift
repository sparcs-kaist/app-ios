//
//  PostBookmarkButton.swift
//  soap
//
//  Created by Soongyu Kwon on 27/05/2025.
//

import Foundation
import SwiftUI
import Haptica


struct PostBookmarkButton: View {
  let isBookmarked: Bool
  let onToggleBookmark: () async -> Void
  
  var body: some View {
    Button(String(localized: "bookmark", bundle: .module), systemImage: isBookmarked ? "bookmark.fill" : "bookmark") {
      Haptic.impact(.light).generate()
      Task {
        await onToggleBookmark()
      }
    }
    .labelStyle(.iconOnly)
    .foregroundStyle(.primary)
    .padding(8)
    .glassEffect(.regular.interactive(), in: .circle)
  }
}
