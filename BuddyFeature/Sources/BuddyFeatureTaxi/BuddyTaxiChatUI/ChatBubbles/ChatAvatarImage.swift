//
//  ChatAvatarImage.swift
//  BuddyTaxiChatUI
//
//  Created by Soongyu Kwon on 16/02/2026.
//

import Foundation
import SwiftUI
import BuddyDomain
import BuddyFeatureShared

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
    TaxiProfilePhoto(url: sender.avatarURL)
      .frame(width: 36, height: 36)
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
