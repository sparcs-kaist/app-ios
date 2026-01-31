//
//  ScrollableTextView.swift
//  soap
//
//  Created by 하정우 on 8/9/25.
//

import SwiftUI

struct ScrollableTextView: View {
  var text: String?
  
  init(_ file: String) {
    self.text = loadMarkdown(from: file)
  }
  
  var body: some View {
    if let text = text {
      bodyText(text: text)
    } else {
      ContentUnavailableView("Failed to load content", systemImage: "exclamationmark.triangle.text.page")
    }
  }
  
  private func bodyText(text: String) -> some View {
    ScrollView {
      HStack {
        Text(LocalizedStringKey(text))
          .multilineTextAlignment(.leading)
        Spacer()
      }
    }
  }
  
  func loadMarkdown(from file: String) -> String? {
    guard let url = Bundle.main.url(forResource: file, withExtension: "md") else {
      return nil
    }
    return try? String(contentsOf: url, encoding: .utf8)
  }
}

#Preview("Loaded State") {
  ScrollableTextView("taxi_privacy_policy").padding()
}

#Preview("Error State") {
  ScrollableTextView("").padding()
}
