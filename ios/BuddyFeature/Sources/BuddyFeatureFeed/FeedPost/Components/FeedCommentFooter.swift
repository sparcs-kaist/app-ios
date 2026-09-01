//
//  FeedCommentFooter.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 25/08/2025.
//

import SwiftUI
import BuddyFeatureShared

/// Reply and vote controls.
struct FeedCommentFooter: View {
  let parentCommentID: String?
  let replyCount: Int
  let isDeleted: Bool
  let myVote: Bool?
  let votes: Int
  let onReply: (() -> Void)?
  let onUpvote: () async -> Void
  let onDownvote: () async -> Void

  var body: some View {
    HStack {
      Spacer()

      if parentCommentID == nil {
        PostCommentButton(commentCount: replyCount) {
          onReply?()
        }
      }

      if !isDeleted {
        PostVoteButton(
          myVote: myVote,
          votes: votes,
          onDownvote: onDownvote,
          onUpvote: onUpvote
        )
      }
    }
    .font(.caption)
    .transition(.blurReplace)
    .animation(.spring, value: votes)
    .frame(height: 20)
  }
}
