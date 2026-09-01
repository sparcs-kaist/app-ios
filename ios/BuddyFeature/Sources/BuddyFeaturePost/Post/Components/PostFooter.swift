//
//  PostFooter.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 15/05/2025.
//

import SwiftUI
import BuddyFeatureShared

/// Vote, comment, bookmark, and share controls.
struct PostFooter: View {
  let myVote: Bool?
  let votes: Int
  let isMine: Bool?
  let commentCount: Int
  let isBookmarked: Bool
  let shareURL: URL
  let onUpvote: () async -> Void
  let onDownvote: () async -> Void
  let onToggleBookmark: () async -> Void
  let onCommentTapped: () -> Void

  var body: some View {
    HStack {
      PostVoteButton(
        myVote: myVote,
        votes: votes,
        onDownvote: onDownvote,
        onUpvote: onUpvote
      )
      .disabled(isMine ?? false)

      PostCommentButton(commentCount: commentCount) {
        onCommentTapped()
      }

      Spacer()

      PostBookmarkButton(
        isBookmarked: isBookmarked,
        onToggleBookmark: onToggleBookmark
      )

      PostShareButton(url: shareURL)
    }
    .font(.callout)
  }
}
