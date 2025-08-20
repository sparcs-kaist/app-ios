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
      HStack(spacing: 4) {
        if let topic = post.topic {
          Text("[\(topic.name.localized())]")
            .font(.subheadline)
            .fontWeight(.medium)
            .lineLimit(1)
            .foregroundStyle(.accent)
        }

        Text(title)
          .font(.subheadline)
          .fontWeight(.semibold)
          .lineLimit(1)
          .foregroundStyle(post.isHidden ? .secondary : .primary)

        if post.attachmentType == .image || post.attachmentType == .both {
          Image(systemName: "photo")
            .font(.subheadline)
            .foregroundStyle(.teal)
        }

        if post.attachmentType == .file || post.attachmentType == .both {
          Image(systemName: "paperclip")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
      }

      HStack(spacing: 12) {
        let voteCount: Int = post.upvotes - post.downvotes
        if voteCount != 0 || post.commentCount > 0 {
          HStack(spacing: 4) {
            PostListRowVoteLabel(voteCount: voteCount)
            PostListRowCommentLabel(commentCount: post.commentCount)
          }
        }

        Text(post.author.profile.nickname)

        Spacer()
        Text("\(post.views) views")

        Text(post.createdAt.timeAgoDisplay)

        Image(systemName: "chevron.right")
          .opacity(post.isHidden ? 0 : 1)
      }
      .font(.caption)
      .foregroundStyle(.secondary)
      .padding(.top, 1)
    }
  }

  var title: String {
    if post.isHidden {
      if post.isNSFW {
        return "This post contains NSFW content"
      }

      if post.isPolitical {
        return "This post contains political content"
      }

      return "This post is hidden"
    }

    return post.title ?? "Untitled"
  }
}
