//
//  TaxiChatUserWrapper.swift
//  soap
//
//  Created by Soongyu Kwon on 17/07/2025.
//

import SwiftUI

struct TaxiChatUserWrapper<Content: View>: View {
  let authorID: String?
  let authorName: String?
  let authorProfileImageURL: URL?
  let isMe: Bool
  @ViewBuilder let content: () -> Content

  var body: some View {
    HStack(alignment: .bottom, spacing: 8) {
      if !isMe {
        if authorID == nil {
          botProfileImage
        } else {
          Circle()
            .frame(width: 36, height: 36)
        }
      } else {
        Spacer(minLength: 80)
      }

      VStack(alignment: isMe ? .trailing : .leading, spacing: 4) {
        if !isMe {
          authorNameplace
            .font(.caption)
            .fontWeight(.medium)
        }
        content()
      }

      if !isMe {
        Spacer(minLength: 80)
      }
    }
  }

  private var botProfileImage: some View {
    ZStack {
      Circle()
        .fill(.indigo.opacity(0.1))
        .frame(width: 36, height: 36)

      Text("🤖")
        .font(.system(size: 20))
    }
  }

  private var authorNameplace: some View {
    Group {
      if let name = authorName {
        Text(name)
      } else if authorID == nil {
        Text("Taxi Bot")
      } else {
        Text("Unknown")
      }
    }
  }
}

#Preview {
  VStack(spacing: 16) {
    TaxiChatUserWrapper(
      authorID: "",
      authorName: "alex",
      authorProfileImageURL: nil,
      isMe: false
    ) {
      TaxiChatBubble(content: "hey", showTip: true, isMe: false)
    }

    TaxiChatUserWrapper(
      authorID: "",
      authorName: "jordan",
      authorProfileImageURL: nil,
      isMe: true
    ) {
      TaxiChatBubble(content: "hey alex!", showTip: true, isMe: true)
    }

    TaxiChatUserWrapper(
      authorID: "",
      authorName: "sam",
      authorProfileImageURL: nil,
      isMe: false
    ) {
      TaxiChatBubble(content: "yo everyone", showTip: false, isMe: false)
      TaxiChatBubble(content: "what's up", showTip: true, isMe: false)
    }

    TaxiChatUserWrapper(
      authorID: "",
      authorName: "alex",
      authorProfileImageURL: nil,
      isMe: false
    ) {
      TaxiChatBubble(content: "how's your day going?", showTip: true, isMe: false)
    }

    TaxiChatUserWrapper(
      authorID: "",
      authorName: "sam",
      authorProfileImageURL: nil,
      isMe: false
    ) {
      TaxiChatBubble(content: "pretty chill", showTip: false, isMe: false)
      TaxiChatBubble(content: "so far", showTip: false, isMe: false)
      TaxiChatBubble(content: "might hit the gym later.", showTip: true, isMe: false)
    }

    TaxiChatUserWrapper(
      authorID: "",
      authorName: "jordan",
      authorProfileImageURL: nil,
      isMe: true
    ) {
      TaxiChatBubble(content: "same here", showTip: false, isMe: true)
      TaxiChatBubble(content: "just working through emails", showTip: true, isMe: true)
    }
  }
  .padding(.leading)
  .padding(.trailing, 8)
}
