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
  let onDownvote: () async -> Void
  let onUpvote: () async -> Void

  @State private var isRunning: Bool = false

  var body: some View {
    HStack {
      Button(action: {
        guard !isRunning else { return }
        isRunning = true
        Task {
          await onUpvote()
          isRunning = false
        }
      }, label: {
        HStack {
          Image(systemName: upvoteImage)
            .foregroundStyle(myVote == true ? Color.upvote : .primary)

          Text("\(votes)")
            .foregroundStyle(myVote != nil ? tintColor : .primary)
            .contentTransition(.numericText(value: Double(votes)))
            .animation(.spring(), value: votes)
        }
      })

      Divider()

      Button("downvote", systemImage: downvoteImage) {
        guard !isRunning else { return }
        isRunning = true
        Task {
          await onDownvote()
          isRunning = false
        }
      }
      .labelStyle(.iconOnly)
      .foregroundStyle(myVote == false ? Color.downvote : .primary)
    }
    .padding(8)
    .fixedSize(horizontal: false, vertical: true)
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
