//
//  TaxiChatGeneralMessage.swift
//  soap
//
//  Created by Soongyu Kwon on 18/07/2025.
//

import SwiftUI

struct TaxiChatGeneralMessage: View {
  let authorName: String
  let type: TaxiChat.ChatType

  var body: some View {
    Group {
      switch type {
      case .entrance:
        Text("\(authorName) has joined")
      case .exit:
        Text("\(authorName) has left")
      default:
        EmptyView()
      }
    }
    .foregroundStyle(.secondary)
    .fontWeight(.medium)
    .font(.footnote)
  }
}
