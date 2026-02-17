//
//  ChatGeneralMessage.swift
//  soap
//
//  Created by Soongyu Kwon on 18/07/2025.
//

import SwiftUI
import BuddyDomain

struct ChatGeneralMessage: View {
  let authorName: String?
  let type: TaxiChat.ChatType

  var body: some View {
    HStack {
      Spacer()

      switch type {
      case .entrance:
        Text("\(authorName ?? "unknown") has joined")
      case .exit:
        Text("\(authorName ?? "unknown") has left")
      default:
        EmptyView()
      }

      Spacer()
    }
    .foregroundStyle(.secondary)
    .fontWeight(.medium)
    .font(.footnote)
  }
}
