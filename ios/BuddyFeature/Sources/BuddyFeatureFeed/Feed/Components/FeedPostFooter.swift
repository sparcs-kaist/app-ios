//
//  FeedPostFooter.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 20/08/2025.
//

import SwiftUI
import BuddyFeatureShared

/// Vote and comment controls.
struct FeedPostFooter: View {
  let myVote: Bool?
  let votes: Int
  let commentCount: Int
  let canComment: Bool
  let onUpvote: () async -> Void
  let onDownvote: () async -> Void
  let onComment: () -> Void

  var body: some View {
    HStack {
      PostVoteButton(
        myVote: myVote,
        votes: votes,
        onDownvote: onDownvote,
        onUpvote: onUpvote
      )

      PostCommentButton(commentCount: commentCount) {
        onComment()
      }
      .allowsHitTesting(canComment)

      Spacer()
    }
    .padding(.horizontal)
    .padding(.top, 4)
  }
}
