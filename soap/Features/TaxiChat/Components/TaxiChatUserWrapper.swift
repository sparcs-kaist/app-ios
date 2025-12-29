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
  let isWithdrawn: Bool
  let badge: Bool
  @ViewBuilder let content: () -> Content
  
  @State private var showPopover: Bool = false

  var body: some View {
    if isGeneral {
      content()
    } else {
      HStack(alignment: .bottom, spacing: 8) {
        // profile picture
        if !isMe {
          if isWithdrawn {
            unknownProfileImage
          } else if authorID == nil {
            botProfileImage
          } else {
            userProfileImage
          }
        } else {
          // spacer for me
          Spacer(minLength: 40)
        }

        VStack(alignment: isMe ? .trailing : .leading, spacing: 4) {
          // nickname label
          if !isMe {
            HStack(spacing: 4) {
              authorNameplace
                .font(.caption)
                .fontWeight(.medium)
              
              if badge {
                Image(systemName: "phone.circle.fill")
                  .foregroundStyle(.accent)
                  .scaleEffect(0.8)
                  .onTapGesture {
                    showPopover.toggle()
                  }
                  .popover(isPresented: $showPopover) {
                    Text("Members with this badge can resolve issues through SPARCS mediation when problems arise.")
                      .font(.caption)
                      .padding()
                      .frame(width: 250)
                      .presentationCompactAdaptation(.popover)
                  }
              }
            }
          }

          // chat bubbles
          VStack(alignment: isMe ? .trailing : .leading, spacing: 4) {
            content()
          }
        }

        // spacer for other users
        if !isMe {
          Spacer(minLength: 40)
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

  private var unknownProfileImage: some View {
    ZStack {
      Circle()
        .fill(.indigo.opacity(0.1))
        .frame(width: 36, height: 36)

      Text("👻")
        .font(.system(size: 20))
    }
  }

  private var authorNameplace: some View {
    Group {
      if isWithdrawn {
        Text("Unknown")
      } else if let name = authorName {
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
      isGeneral: false,
      isWithdrawn: false,
      badge: true
    ) {
      TaxiChatBubble(content: "hey", showTip: true, isMe: false)
    }

    TaxiChatUserWrapper(
      authorID: "",
      authorName: "jordan",
      authorProfileImageURL: nil,
      date: Date(),
      isMe: true,
      isGeneral: false,
      isWithdrawn: false,
      badge: false
    ) {
      TaxiChatBubble(content: "hey alex!", showTip: true, isMe: true)
    }

    TaxiChatUserWrapper(
      authorID: "",
      authorName: "sam",
      authorProfileImageURL: nil,
      date: Date(),
      isMe: false,
      isGeneral: false,
      isWithdrawn: false,
      badge: true
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
      isGeneral: false,
      isWithdrawn: false,
      badge: false
    ) {
      TaxiChatBubble(content: "how's your day going?", showTip: true, isMe: false)
    }

    TaxiChatUserWrapper(
      authorID: "",
      authorName: "sam",
      authorProfileImageURL: nil,
      date: Date(),
      isMe: false,
      isGeneral: false,
      isWithdrawn: false,
      badge: true
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
      isGeneral: false,
      isWithdrawn: false,
      badge: true
    ) {
      TaxiChatBubble(content: "same here", showTip: false, isMe: true)
      TaxiChatBubble(content: "just working through emails", showTip: true, isMe: true)
    }
  }
  .padding(.leading)
  .padding(.trailing, 8)
}
