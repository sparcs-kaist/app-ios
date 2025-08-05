//
//  PostListRow.swift
//  soap
//
//  Created by Soongyu Kwon on 15/02/2025.
//

import SwiftUI

struct PostListRow: View {
  let post: Post

  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text(post.title)
          .font(.subheadline)
          .fontWeight(.semibold)
          .lineLimit(1)

        HStack(spacing: 12) {
          if post.voteCount != 0 || post.commentCount > 0 {
            HStack(spacing: 4) {
              PostListRowVoteLabel(voteCount: post.voteCount)
              PostListRowCommentLabel(commentCount: post.commentCount)
            }
          }

          Text(post.author)

          Spacer()
          Text("30 views")

          Text(post.createdAt.timeAgoDisplay())
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.top, 1)
      }

      Spacer()
    }
  }

//  var body: some View {
//    HStack {
//      VStack(alignment: .leading) {
//        Text(post.title)
//          .font(.subheadline)
//          .fontWeight(.semibold)
//          .lineLimit(1)
//        Text(post.description)
//          .font(.footnote)
//          .foregroundStyle(.secondary)
//          .lineLimit(2)
//
//        HStack(spacing: 12) {
//          if post.voteCount != 0 || post.commentCount > 0 {
//            HStack(spacing: 4) {
//              PostListRowVoteLabel(voteCount: post.voteCount)
//              PostListRowCommentLabel(commentCount: post.commentCount)
//            }
//          }
//
//          Text(post.author)
//
//          Text(post.createdAt.timeAgoDisplay())
//        }
//        .font(.caption)
//        .foregroundStyle(.secondary)
//        .padding(.top, 1)
//      }
//
//      Spacer()
//
//      if post.thumbnailURL != nil {
//        RoundedRectangle(cornerRadius: 8)
//          .aspectRatio(1.0, contentMode: .fit)
//          .frame(width: 72, height: 72)
//          .foregroundStyle(Color(UIColor.systemGray5))
//      }
//    }
//  }
}

#Preview {
  List {
    PostListRow(
      post: Post(
        title: "some title",
        description: "verrrry loooonnngggg description",
        voteCount: 10,
        commentCount: 20,
        author: "Anonymous",
        createdAt: Calendar.current.date(byAdding: .hour, value: -3, to: Date())!,
        thumbnailURL: nil
      )
    )
    PostListRow(
      post: Post(
        title: "some title",
        description: "verrrry loooonnngggg asdfojapsdofpoweufpoqiewfpoqiuwepfoiquwepfoiquwepfoiqwuepfoiqwuepfoiquwepfoiquwepofiquwepofiuqpwoeifuqpwoeifuqpwoeifu",
        voteCount: -100,
        commentCount: 0,
        author: "Anonymous",
        createdAt: Calendar.current.date(byAdding: .day, value: -30, to: Date())!,
        thumbnailURL: URL(string: "https://newara.sparcs.org")
      )
    )
    PostListRow(
      post: Post(
        title: "some title",
        description: "verrrry loooonnngggg description",
        voteCount: 122,
        commentCount: 1,
        author: "Anonymous",
        createdAt: Calendar.current.date(byAdding: .minute, value: -30, to: Date())!,
        thumbnailURL: nil
      )
    )
    PostListRow(
      post: Post(
        title: "some title",
        description: "verrrry loooonnngggg description",
        voteCount: 0,
        commentCount: 0,
        author: "Anonymous",
        createdAt: Calendar.current.date(byAdding: .second, value: -30, to: Date())!,
        thumbnailURL: nil
      )
    )
    PostListRow(
      post: Post(
        title: "some title",
        description: "verrrry loooonnngggg description",
        voteCount: 0,
        commentCount: 0,
        author: "Anonymous",
        createdAt: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
        thumbnailURL: nil
      )
    )
  }
  .listStyle(.plain)
}
