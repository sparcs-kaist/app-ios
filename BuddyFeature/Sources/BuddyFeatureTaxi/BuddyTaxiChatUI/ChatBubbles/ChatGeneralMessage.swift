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
        Text(String(localized: "\(authorName ?? "unknown") has joined", bundle: .module))
      case .exit:
        Text(String(localized: "\(authorName ?? "unknown") has left", bundle: .module))
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
