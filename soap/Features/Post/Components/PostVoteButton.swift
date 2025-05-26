//
//  PostVoteButton.swift
//  soap
//
//  Created by Soongyu Kwon on 27/05/2025.
//

import SwiftUI

struct PostVoteButton: View {
  var body: some View {
    HStack {
      Button("downvote", systemImage: "arrow.down") {

      }
      .labelStyle(.iconOnly)
      .foregroundStyle(.primary)

      Divider()

      Button(action: {

      }, label: {
        HStack {
          Text("13")

          Image(systemName: "arrow.up")
        }
      })
      .foregroundStyle(.primary)
    }
    .padding(8)
    .background {
      Capsule()
        .stroke(Color(uiColor: .separator))
    }
  }
}
