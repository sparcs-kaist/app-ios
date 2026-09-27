//
//  FeedCommentReplyPreview.swift
//  BuddyFeature
//
//  Created by Soongyu Kwon on 27/09/2026.
//

import SwiftUI

/// A compact quote of the comment being replied to, shown above the comment
/// input so the user knows where their reply will go.
struct FeedCommentReplyPreview: View {
  let authorName: String
  let content: String
  let isDeleted: Bool
  let onCancel: () -> Void

  var body: some View {
    HStack(alignment: .top, spacing: 8) {
      Capsule()
        .fill(.tint)
        .frame(width: 3)

      VStack(alignment: .leading, spacing: 2) {
        Text("Replying to \(authorName)", bundle: .module)
          .font(.caption)
          .fontWeight(.semibold)
          .foregroundStyle(.tint)

        Group {
          if isDeleted {
            Text("This comment has been deleted.", bundle: .module)
          } else {
            Text(content)
          }
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .lineLimit(2)
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      Button(String(localized: "Cancel", bundle: .module), systemImage: "xmark", action: onCancel)
        .labelStyle(.iconOnly)
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundStyle(.secondary)
        .contentShape(.rect)
    }
    .fixedSize(horizontal: false, vertical: true)
  }
}

#Preview {
  FeedCommentReplyPreview(
    authorName: "Buddy",
    content: "This is a long comment that should be truncated after two lines so the input bar stays compact while replying to it.",
    isDeleted: false,
    onCancel: {}
  )
  .padding()
}
