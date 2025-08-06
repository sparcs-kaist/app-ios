//
//  PostVoteButton.swift
//  soap
//
//  Created by Soongyu Kwon on 27/05/2025.
//

import SwiftUI

struct PostVoteButton: View {
  let myVote: Bool?
  let votes: Int
  let onDownvote: () -> Void
  let onUpvote: () -> Void

  var body: some View {
    HStack {
      Button("downvote", systemImage: downvoteImage) {

      }
      .labelStyle(.iconOnly)
      .foregroundStyle(myVote == false ? Color.downvote : .primary)

      Divider()

      Button(action: {

      }, label: {
        HStack {
          Text("13")
            .foregroundStyle(myVote != nil ? tintColor : .primary)

          Image(systemName: upvoteImage)
            .foregroundStyle(myVote == true ? Color.upvote : .primary)
        }
      })
    }
    .padding(8)
    .glassEffect(.regular.interactive())
  }

  var tintColor: Color {
    guard let myVote = myVote else {
      return .primary
    }

    return myVote ? .upvote : .downvote
  }

  var downvoteImage: String {
    return myVote == false ? "arrowshape.down.fill" : "arrowshape.down"
  }

  var upvoteImage: String {
    return myVote == true ? "arrowshape.up.fill" : "arrowshape.up"
  }
}


#Preview {
  @Previewable @State var myVote: Bool? = nil
  @Previewable @State var votes: Int = 13

  HStack {
    PostVoteButton(myVote: myVote, votes: votes, onDownvote: {

    }, onUpvote: {

    })
  }
  .padding()
}
