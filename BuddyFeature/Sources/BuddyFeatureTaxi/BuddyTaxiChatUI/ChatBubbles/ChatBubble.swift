//
//  ChatBubble.swift
//  BuddyTaxiChatUI
//
//  Created by Soongyu Kwon on 14/02/2026.
//

import SwiftUI
import BuddyDomain
import BuddyFeatureShared

struct ChatBubble: View {
  let chat: TaxiChat
  let position: ChatBubblePosition
  let isMine: Bool

  @State private var selectedURL: URL?

  var body: some View {
    Text(formattedContent)
      .padding(12)
      .background(
        isMine ? Color.accentColor : .secondarySystemBackground,
        in: .rect(
          topLeadingRadius: 24,
          bottomLeadingRadius: !isMine && (position == .bottom || position == .single) ? 4 : 24,
          bottomTrailingRadius: isMine && (position == .bottom || position == .single) ? 4 : 24,
          topTrailingRadius: 24
        )
      )
      .foregroundStyle(isMine ? .white : .primary)
      .tint(isMine ? .white.opacity(0.8) : Color.accentColor)
      .environment(\.openURL, OpenURLAction(handler: handleURL))
      .sheet(item: $selectedURL) { url in
        SafariViewWrapper(url: url)
      }
      .contextMenu {
        Button("Copy", systemImage: "doc.on.doc") {
          UIPasteboard.general.string = chat.content
        }
      }
  }

  private func handleURL(_ url: URL) -> OpenURLAction.Result {
    selectedURL = url
    return .handled
  }

  var formattedContent: String {
    var newText = chat.content

    guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
      return chat.content
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


//#Preview {
//  let mock: [TaxiChat] = TaxiChat.mockList
//  let builder = ChatRenderItemBuilder(
//    policy: TaxiGroupingPolicy(),
//    positionResolver: ChatBubblePositionResolver(),
//    presentationPolicy: DefaultMessagePresentationPolicy()
//  )
//  let items = builder.build(chats: mock, myUserID: "user1")
//
//  LazyVStack {
//    ForEach(items, id: \.self) { item in
//      switch item {
//      case .message(_, let chat, let position, let isMine, _, _, _):
//        ChatBubble(
//          chat: chat,
//          position: position,
//          isMine: isMine
//        )
//      default:
//        EmptyView()
//      }
//    }
//  }
//  .padding()
//}
