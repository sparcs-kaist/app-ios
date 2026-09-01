//
//  PostCommentCellFooter.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 07/08/2025.
//

import SwiftUI
import BuddyFeatureShared

/// Reply and vote controls for a comment.
struct PostCommentCellFooter: View {
  let isThreaded: Bool
  let isDeleted: Bool
  let replyCount: Int
  let myVote: Bool?
  let votes: Int
  let isMine: Bool?
  let onComment: (() -> Void)?
  let onUpvote: () async -> Void
  let onDownvote: () async -> Void

  var body: some View {
    HStack {
      Spacer()

      if !isThreaded {
        PostCommentButton(commentCount: replyCount) {
          onComment?()
        }
        .fixedSize()
      }

      if !isDeleted {
        PostVoteButton(
          myVote: myVote,
          votes: votes,
          onDownvote: onDownvote,
          onUpvote: onUpvote
        )
        .disabled(isMine ?? false)
        .fixedSize()
      }
    }
    .font(.caption)
    .transition(.blurReplace)
  }
}
