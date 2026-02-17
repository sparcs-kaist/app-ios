//
//  ChatAvatarImage.swift
//  BuddyTaxiChatUI
//
//  Created by Soongyu Kwon on 16/02/2026.
//

import SwiftUI
import NukeUI
import BuddyDomain

struct ChatAvatarImage: View {
  let sender: SenderInfo

  var body: some View {
    if sender.isWithdrew {
      unknownAvatarImage
    } else if sender.id == nil {
      botAvatarImage
    } else {
      userAvatarImage
    }
  }

  private var userAvatarImage: some View {
    Group {
      if let url = sender.avatarURL {
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

  private var botAvatarImage: some View {
    ZStack {
      Circle()
        .fill(.indigo.opacity(0.1))
        .frame(width: 36, height: 36)

      Text("🤖")
        .font(.system(size: 20))
    }
  }

  private var unknownAvatarImage: some View {
    ZStack {
      Circle()
        .fill(.indigo.opacity(0.1))
        .frame(width: 36, height: 36)

      Text("👻")
        .font(.system(size: 20))
    }
  }
}
