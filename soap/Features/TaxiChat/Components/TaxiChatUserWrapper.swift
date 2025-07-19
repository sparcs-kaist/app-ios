//
//  TaxiChatUserWrapper.swift
//  soap
//
//  Created by Soongyu Kwon on 17/07/2025.
//

import SwiftUI
import NukeUI

struct TaxiChatUserWrapper<Content: View>: View {
  let authorID: String?
  let authorName: String?
  let authorProfileImageURL: URL?
  let date: Date?
  let isMe: Bool
  let isGeneral: Bool
  @ViewBuilder let content: () -> Content

  var body: some View {
    if isGeneral {
      content()
    } else {
      HStack(alignment: .bottom, spacing: 8) {
        // profile picture
        if !isMe {
          if authorID == nil {
            botProfileImage
          } else {
            userProfileImage
          }
        } else {
          // spacer for me
          Spacer(minLength: 60)
        }

        VStack(alignment: isMe ? .trailing : .leading, spacing: 4) {
          // nickname label
          if !isMe {
            authorNameplace
              .font(.caption)
              .fontWeight(.medium)
          }

          // chat bubbles
          VStack(alignment: isMe ? .trailing : .leading, spacing: 4) {
            content()
          }
        }

        // spacer for other users
        if !isMe {
          Spacer(minLength: 60)
        }
      }
    }
  }

  private var userProfileImage: some View {
    Group {
      if let url = authorProfileImageURL {
        LazyImage(url: url) { state in
          if let image = state.image {
            image
              .resizable()
              .aspectRatio(contentMode: .fill)
          } else {
            Circle()
              .fill(Color.secondarySystemBackground)
          }
        }
        .frame(width: 36, height: 36)
        .clipShape(.circle)
      } else {
        Circle()
          .fill(Color.secondarySystemBackground)
          .frame(width: 36, height: 36)
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
      date: Date(),
      isMe: false,
      isGeneral: false
    ) {
      TaxiChatBubble(content: "hey", showTip: true, isMe: false)
    }

    TaxiChatUserWrapper(
      authorID: "",
      authorName: "jordan",
      authorProfileImageURL: nil,
      date: Date(),
      isMe: true,
      isGeneral: false
    ) {
      TaxiChatBubble(content: "hey alex!", showTip: true, isMe: true)
    }

    TaxiChatUserWrapper(
      authorID: "",
      authorName: "sam",
      authorProfileImageURL: nil,
      date: Date(),
      isMe: false,
      isGeneral: false
    ) {
      TaxiChatBubble(content: "yo everyone", showTip: false, isMe: false)
      TaxiChatBubble(content: "what's up", showTip: true, isMe: false)
    }

    TaxiChatUserWrapper(
      authorID: "",
      authorName: "alex",
      authorProfileImageURL: nil,
      date: Date(),
      isMe: false,
      isGeneral: false
    ) {
      TaxiChatBubble(content: "how's your day going?", showTip: true, isMe: false)
    }

    TaxiChatUserWrapper(
      authorID: "",
      authorName: "sam",
      authorProfileImageURL: nil,
      date: Date(),
      isMe: false,
      isGeneral: false
    ) {
      TaxiChatBubble(content: "pretty chill", showTip: false, isMe: false)
      TaxiChatBubble(content: "so far", showTip: false, isMe: false)
      TaxiChatBubble(content: "might hit the gym later.", showTip: true, isMe: false)
    }

    TaxiChatUserWrapper(
      authorID: "",
      authorName: "jordan",
      authorProfileImageURL: nil,
      date: Date(),
      isMe: true,
      isGeneral: false
    ) {
      TaxiChatBubble(content: "same here", showTip: false, isMe: true)
      TaxiChatBubble(content: "just working through emails", showTip: true, isMe: true)
    }
  }
  .padding(.leading)
  .padding(.trailing, 8)
}
