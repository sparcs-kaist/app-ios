//
//  PostListRow.swift
//  soap
//
//  Created by Soongyu Kwon on 15/02/2025.
//

import SwiftUI

struct PostListRow: View {
  let post: AraPost

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(post.title ?? "CENSORED")
        .font(.subheadline)
        .fontWeight(.semibold)
        .lineLimit(1)

      HStack(spacing: 12) {
        let voteCount: Int = post.positiveVoteCount - post.negativeVoteCount
        if voteCount != 0 || post.commentCount > 0 {
          HStack(spacing: 4) {
            PostListRowVoteLabel(voteCount: voteCount)
            PostListRowCommentLabel(commentCount: post.commentCount)
          }
        }

        Text(post.author.profile.nickname)

        Spacer()
        Text("\(post.views) views")

        Text(post.createdAt.timeAgoDisplay())
      }
      .font(.caption)
      .foregroundStyle(.secondary)
      .padding(.top, 1)
    }
  }
}
