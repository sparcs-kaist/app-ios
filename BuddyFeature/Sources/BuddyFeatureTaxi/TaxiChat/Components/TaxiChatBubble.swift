//
//  TaxiChatBubble.swift
//  soap
//
//  Created by Soongyu Kwon on 17/07/2025.
//

import SwiftUI
import BuddyFeatureShared

struct TaxiChatBubble: View {
  let content: String
  let showTip: Bool
  let isMe: Bool

  @State private var selectedURL: URL?

  var body: some View {
    Text(.init(formattedContent))
      .padding(12)
      .background(
        isMe ? Color.accentColor : .secondarySystemBackground,
        in: .rect(
          topLeadingRadius: 24,
          bottomLeadingRadius: !isMe && showTip ? 4 : 24,
          bottomTrailingRadius: isMe && showTip ? 4 : 24,
          topTrailingRadius: 24
        )
      )
      .foregroundStyle(isMe ? .white : .primary)
      .tint(isMe ? .white.opacity(0.8) : Color.accentColor)
      .environment(\.openURL, OpenURLAction(handler: handleURL))
      .sheet(item: $selectedURL) { url in
        SafariViewWrapper(url: url)
      }
      .contextMenu {
        Button("Copy", systemImage: "doc.on.doc") {
          UIPasteboard.general.string = content
        }
      }
  }

  private func handleURL(_ url: URL) -> OpenURLAction.Result {
    selectedURL = url
    return .handled
  }

  var formattedContent: String {
    var newText = content

    guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
      return content
    }

    let matches = detector.matches(in: newText, options: [], range: NSRange(location: 0, length: newText.utf16.count))

    for match in matches.reversed() {
      guard let range = Range(match.range, in: newText) else { continue }
      let urlString = String(newText[range])
      let markdownLink = "[\(urlString)](\(urlString))"
      newText.replaceSubrange(range, with: markdownLink)
    }

    return newText
  }
}

// MARK: - Preview
#Preview {
  VStack(spacing: 8) {
    TaxiChatBubble(content: "Visit https://naver.com now!", showTip: true, isMe: true)
    TaxiChatBubble(content: "Here is a link: https://apple.com and some more text.", showTip: true, isMe: false)
    TaxiChatBubble(content: "No link here just chatting casually", showTip: false, isMe: true)
    TaxiChatBubble(content: "Multiple links: https://swift.org and also https://developer.apple.com", showTip: true, isMe: false)
  }
  .padding()
}
