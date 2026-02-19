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
    Text(chat.content.toDetectedAttributedString())
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
