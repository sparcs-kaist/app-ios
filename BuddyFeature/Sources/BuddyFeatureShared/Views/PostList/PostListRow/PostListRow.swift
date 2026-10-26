//
//  PostListRow.swift
//  soap
//
//  Created by Soongyu Kwon on 15/02/2025.
//

import Foundation
import SwiftUI
import BuddyDomain

public struct PostListRow: View {
  let post: AraPost

  public init(post: AraPost) {
    self.post = post
  }

  /// Read posts are greyed out; one with new comments or edits since (`.updated`) stays prominent.
  private var isRead: Bool {
    post.readStatus == .read
  }

  public var body: some View {
    if post.isHidden {
      hiddenBody
    } else {
      postBody
    }
  }

  /// One quiet line: why the post is hidden, and when it was posted. The author is left out so
  /// a blocked person's name doesn't appear either.
  private var hiddenBody: some View {
    HStack(spacing: 8) {
      Image(systemName: post.hiddenSymbol)
        .font(.subheadline)
        .foregroundStyle(.tertiary)
        .frame(width: 20)
      Text(title)
        .font(.subheadline)
        .lineLimit(1)
      Spacer()
      Text(post.createdAt.timeAgoDisplay)
        .font(.caption)
    }
    .foregroundStyle(.secondary)
    .padding(.vertical, 2)
    .accessibilityElement(children: .combine)
  }

  private var postBody: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack(spacing: 4) {
        // Read before, but commented on or edited since.
        if post.readStatus == .updated {
          Circle()
            .fill(Color.accentColor)
            .frame(width: 7, height: 7)
            .accessibilityLabel(Text("Updated", bundle: .module))
        }

        if let topic = post.topic {
          Text("[\(topic.name.localized())]")
            .font(.subheadline)
            .fontWeight(.medium)
            .lineLimit(1)
            .foregroundStyle(Color.accentColor.opacity(isRead ? 0.5 : 1))
        }

        Text(title)
          .font(.subheadline)
          .fontWeight(.semibold)
          .lineLimit(1)
          .foregroundStyle(isRead ? .secondary : .primary)

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

      HStack(spacing: 0) {
        let voteCount: Int = post.upvotes - post.downvotes
        HStack(spacing: 12) {
          if voteCount != 0 || post.commentCount > 0 {
            HStack(spacing: 4) {
              PostListRowVoteLabel(voteCount: voteCount)
              PostListRowCommentLabel(commentCount: post.commentCount)
            }
          }

          Text(post.author.profile.nickname)
        }

        Spacer()
        
        HStack(spacing: 12) {
          Text("\(post.views) views", bundle: .module)

          Text(post.createdAt.timeAgoDisplay)

          Image(systemName: "chevron.right")
        }
      }
      .font(.caption)
      .foregroundStyle(.secondary)
      .padding(.top, 1)
      .lineLimit(1)
    }
  }

  var title: String {
    post.listTitle
  }
}
