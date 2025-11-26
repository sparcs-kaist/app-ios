//
//  TaxiChatImageBubble.swift
//  soap
//
//  Created by Soongyu Kwon on 28/07/2025.
//

import SwiftUI
import NukeUI
import Playgrounds

struct TaxiChatImageBubble: View {
  let id: String

  var body: some View {
    LazyImage(url: Constants.taxiChatImageURL.appending(path: id)) { state in
      if let image = state.image {
        image
          .resizable()
          .scaledToFit()
          .frame(maxHeight: 360)
          .clipShape(.rect(cornerRadius: 24))
      } else {
        RoundedRectangle(cornerRadius: 24)
          .foregroundStyle(Color.secondarySystemBackground)
          .frame(width: 200, height: 300)
      }
    }
    .processors([.resize(height: 360)])
    .priority(.veryHigh)
  }
}

#Preview {
  TaxiChatUserWrapper(
    authorID: nil,
    authorName: nil,
    authorProfileImageURL: nil,
    date: Date(),
    isMe: false,
    isGeneral: false,
    isWithdrawn: false,
    badge: true
  ) {
    TaxiChatImageBubble(id: "688714fb95fce20ddc8f19da")
  }
  .padding()
}
