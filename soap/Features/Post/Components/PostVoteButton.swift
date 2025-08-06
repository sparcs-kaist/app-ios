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
      Button("downvote", systemImage: "arrowshape.down") {

      }
      .labelStyle(.iconOnly)
      .foregroundStyle(.primary)

      Divider()

      Button(action: {

      }, label: {
        HStack {
          Text("13")

          Image(systemName: "arrowshape.up")
        }
      })
      .foregroundStyle(.primary)
    }
    .padding(8)
    .glassEffect(.regular.interactive())
  }
}


#Preview {
  HStack {
    PostVoteButton()
  }
  .padding()
}
